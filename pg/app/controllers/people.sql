begin;

  create or replace function controllers.people_all(
    req http.request
  ) returns http.response as $$
  declare
  people models.people[] := (select array_agg(people) from models.people);
  begin
    return http.response(
      status := 200,
      headers := array[
        http.header('Content-Type', 'text/html')
      ],
      body := views.people_index(people)
    );
  end
  $$ language plpgsql strict stable security invoker;

  create or replace function controllers.people_create(
    req http.request
  ) returns http.response as $$
  declare
  form_values jsonb := http.parse_form_body(req.body);
  people models.people[];
  begin
    insert into models.people (name) values (form_values->>'name');

    select (select array_agg(ps) from models.people ps) into people;

    return http.response(
      status := 201,
      headers := array[
        http.header('Content-Type', 'text/html')
      ],
      body := views.people_index(people)
    );
  end
  $$ language plpgsql strict volatile security invoker;

commit;
