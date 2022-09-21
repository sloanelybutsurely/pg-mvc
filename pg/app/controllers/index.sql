begin;

  create or replace function controllers.hello(
    req http.request
  ) returns http.response as $$
    select http.response(
      status := 200,
      headers := array[
        http.header('Content-Type', 'text/plain')
      ],
      body := 'Hello, World!'
    );
  $$ language sql immutable security invoker;

commit;
