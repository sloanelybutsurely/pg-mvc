\include_relative views/index.sql
\include_relative controllers/index.sql

create schema if not exists app;

create or replace function app.main(
  req http.request
) returns http.response as $$
  select router.run_router(
    router.make_router(
      router.route('GET', '/', 'controllers.hello'),
      router.route('GET', '/cool', 'i_dont_exist')
    ),
    req
  );
$$ language sql strict volatile security invoker;
