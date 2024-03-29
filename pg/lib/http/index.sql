begin;
  create schema if not exists http;

  select pg_temp.create_enum_if_not_exists('http.method',
    'GET',
    'HEAD',
    'POST',
    'PUT',
    'DELETE',
    'OPTIONS',
    'PATCH'
  );

  select pg_temp.create_type_if_not_exists('http.header',
    ('name', 'text'),
    ('value', 'text')
  );

  create or replace function http.header(
    name text,
    value text
  ) returns http.header as $$
    select row(name, value)::http.header;
  $$ language sql immutable security invoker; 

  select pg_temp.create_type_if_not_exists('http.request',
    ('method', 'http.method'),
    ('path', 'text'),
    ('headers', 'http.header[]'),
    ('body', 'text')
  );

  create or replace function http.request(
    method http.method,
    path text,
    headers http.header[] default '{}',
    body text default null
  ) returns http.request as $$
    select row(
      method,
      path,
      headers,
      body
    )::http.request;
  $$ language sql immutable security invoker;

  do $$
  begin
    create domain http.status_code as integer
      not null check (int4range(100, 600) @> value);
  exception when others then
    raise notice 'Domain "http.status_code" exists, skipping';
  end $$;

  \include_relative http_status_text.sql

  select pg_temp.create_type_if_not_exists('http.response',
    ('status', 'http.status_code'),
    ('headers', 'http.header[]'),
    ('body', 'text')
  );

  create or replace function http.response(
    status http.status_code,
    headers http.header[] default '{}',
    body text default null
  ) returns http.response as $$
    select row(
      status,
      headers,
      body
    )::http.response;
  $$ language sql immutable security invoker;

  create or replace function http.header_to_text(
    header http.header
  ) returns text as $$
    select concat(header.name, ': ', header.value);
  $$ language sql immutable security invoker; 

  do $$
  begin
    create cast (http.header as text) with function http.header_to_text;
  exception when others then
    raise notice 'Cast "(http.header as text)" exists, skipping';
  end $$;

  create or replace function http.response_to_text(
    response http.response
  ) returns text as $$
    select
      array_to_string(array_agg(trim(both ' ' from line)), E'\n')
    from unnest(ARRAY[
      format('HTTP/1.1 %s %s', response.status, http.status_text(response.status)),
      array_to_string(response.headers::text[], E'\n'),
      http.header('Content-Length', coalesce(length(response.body), 0)::text)::text,
      '',
      response.body
    ]) line
  $$ language sql immutable security invoker;

  select pg_temp.create_type_if_not_exists('http.path',
    ('pathname', 'text'),
    ('search_params', 'jsonb')
  );

  create or replace function http.path(
    pathname text default '/',
    search_params jsonb default '{}'
  ) returns http.path as $$
    select row(pathname, search_params)::http.path;
  $$ language sql immutable security invoker;

  create or replace function http.parse_search(
    search text
  ) returns jsonb as $$
    select jsonb_object_agg(
      (string_to_array(token, '='))[1],
      (string_to_array(token, '='))[2]
    )
    from unnest(string_to_array(search, '&')) token
  $$ language sql immutable security invoker;

  create or replace function http.parse_path(
    path text
  ) returns http.path as $$
  declare
  pathname text := (string_to_array(path, '?'))[1];
  search text := (string_to_array(path, '?'))[2];
  begin
    return http.path(
      pathname := pathname,
      search_params := http.parse_search(search)
    );
  end
  $$ language plpgsql immutable security invoker;

  create or replace function http.parse_form_body(
    body text
  ) returns jsonb as $$
    select http.parse_search(body);
  $$ language sql immutable security invoker;

commit;
