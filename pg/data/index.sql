begin;

  create schema if not exists models;

  create table if not exists models.people (
    id integer not null primary key generated always as identity,
    name text not null
  );

commit;
