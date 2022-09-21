\include_relative people.sql

begin;

  create or replace function controllers.hello(
    req http.request
  ) returns http.response as $$
    select http.response(
      status := 200,
      headers := array[
        http.header('Content-Type', 'text/html')
      ],
      body := views.hello(
        greetee := coalesce((http.parse_path(req.path)).search_params->>'name', 'World')
      )::text
    );
  $$ language sql immutable security invoker;

commit;
