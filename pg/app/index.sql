\include_relative views/index.sql
\include_relative controllers/index.sql

create schema if not exists app;

create or replace function app.main(
  req http.request
) returns http.response as $$
  select router.run_router(
    router.make_router(
      router.route('GET', '/', 'controllers.hello')
    ),
    req
  );
$$ language sql strict volatile security invoker;
