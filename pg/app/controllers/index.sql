begin;

  create or replace function controllers.hello(
    req http.request
  ) returns http.response as $$
    select http.response(
      status := 200,
      headers := array[
        http.header('Content-Type', 'text/html')
      ],
      body := xmlelement(name html, xmlelement(name body, xmlelement(name h1, 'Hello, World')))::text
    );
  $$ language sql immutable security invoker;


commit;
