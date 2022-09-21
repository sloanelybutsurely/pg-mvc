\include_relative views/index.sql
\include_relative controllers/index.sql

begin;
  create schema if not exists app;

  create or replace function app.main(
    req http.request
  ) returns http.response as $$
    select router.run_router(
      router.make_router(
        router.route('GET', '/people.*', 'controllers.people_all'),
        router.route('POST', '/people', 'controllers.people_create'),
        router.route('GET', '/.*', 'controllers.hello')
      ),
      req
    );
  $$ language sql strict volatile security invoker;

commit;
