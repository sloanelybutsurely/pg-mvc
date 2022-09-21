begin;
  create schema if not exists router;

  select pg_temp.create_type_if_not_exists('router.route',
    ('method', 'http.method'),
    ('path', 'text'),
    ('controller', 'regproc')
  );

  create or replace function router.route(
    method http.method,
    path text,
    controller regproc
  ) returns router.route as $$
    select row(
      method,
      path,
      controller
    )::router.route;
  $$ language sql immutable security invoker;

  create or replace function router.make_router(
    variadic routes router.route[]
  ) returns router.route[] as $$
    select routes;
  $$ language sql immutable security invoker;

  create or replace function router.matches(
    route router.route,
    req http.request
  ) returns boolean as $$
    select route.method = req.method and req.path ~ route.path;
  $$ language sql immutable security invoker;

  create or replace function router.match(
    router router.route[],
    req http.request
  ) returns router.route as $$
    select route
    from unnest(router) route
    where router.matches(route, req)
    limit 1;
  $$ language sql immutable security invoker;

  create or replace function router.run_router(
    router router.route[],
    req http.request
  ) returns http.response as $$
  declare
  matched router.route := router.match(router, req);
  res http.response;
  begin
    if matched is not null then
      execute format('select * from %s($1)', matched.controller::text) into res using req;
      return res;
    else
      return http.response(
        status := 404,
        headers := array[
          http.header('Content-Type', 'text/plain')
        ],
        body := 'Not Found'
      );
    end if;
  end
  $$ language plpgsql volatile security invoker;

commit;
