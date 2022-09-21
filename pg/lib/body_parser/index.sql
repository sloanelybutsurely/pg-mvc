begin;

  create schema if not exists body_parser;

  create or replace function body_parser.json(
    body text
  ) returns jsonb as $$
    select body::jsonb;
  $$ language sql immutable security invoker;

  create or replace function body_parser.url_decode(
    token text
  ) returns text as $$
  declare
  escaped_seqs text[] := (
    select array_agg(m[1]) from regexp_matches(token, '%[0-9A-F]{2}', 'g') m
  );
  replacements jsonb[] := (
    select coalesce(array_agg(
      jsonb_build_object(
        'sequence', seq,
        'replacement', convert_from(decode(replace(seq, '%', ''), 'hex'), 'UTF8')
      )
    ), '{}')
    from unnest(escaped_seqs) seq
  );
  r jsonb;
  replaced text := token;
  begin
    foreach r in array replacements loop
      replaced := replace(replaced, r->>'sequence', r->>'replacement');
    end loop;
    return replaced;
  end
  $$ language plpgsql immutable security invoker;

  create or replace function body_parser.form_data(
    body text
  ) returns jsonb as $$
    select jsonb_object_agg(
      (string_to_array(token, '='))[1],
      body_parser.url_decode(replace((string_to_array(token, '='))[2], '+', ' '))
    )
    from unnest(string_to_array(body, '&')) token
  $$ language sql immutable security invoker;

  select body_parser.url_decode('name=A%2BVery%2FCool-Thing');

commit;
