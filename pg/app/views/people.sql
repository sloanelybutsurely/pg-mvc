begin;

  create or replace function views.people_form() returns xml as $$
    select xmlparse (content '
      <form method="POST" action="/people" id="new-person" data-trimmings-replace="#people-table, #new-person">
        <label>
          Name
          <input type="text" name="name" required="true" />
        </label>
        <button type="submit">Add person</button>
      </form>
    ');
  $$ language sql immutable security invoker;

  create or replace function views.people_table(
    people models.people[]
  ) returns xml as $$
    select xmlparse (content '
      <table>
        <thead>
          <tr>
            <td>ID</td>
            <td>Name</td>
          </tr>
        </thead>
        <tbody> ' || (
          select coalesce(xmlagg(
            xmlparse (content '<tr><td>' || person.id ||'</td><td>' || person.name || '</td></tr>')
          ), xmlcomment('No people')) from unnest(people) person
        ) || '</tbody>
      </table>
    ');
  $$ language sql immutable security invoker;

  create or replace function views.people_index(
    people models.people[]
  ) returns text as $$
    select templates.main(
      title := 'People',
      content := 
        xmlparse (content '
          <header>
            <h1>All People</h1>
          </header>
          <section id="people-table">
            ' || views.people_table(people) || '
          </section>
          <section>' || views.people_form() || '</section>')
    )::text;
  $$ language sql immutable security invoker;

commit;
