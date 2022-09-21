\include_relative templates/index.sql
\include_relative people.sql


begin;
  create schema if not exists views;

  create or replace function views.hello(
    greetee text
  ) returns xml as $$
    select templates.main(
      xmlelement(name h1, 'Hello, ', xmlelement(name span, greetee), '!'),
      title := 'Hello'
    );
  $$ language sql immutable security invoker;

commit;
