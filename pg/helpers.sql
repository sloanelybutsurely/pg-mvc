-- create all helper function on `pg_temp` schema and they will be removed after migration

create type pg_temp.attr as (
  name text,
  type text
);

create type pg_temp.attr_existence as enum (
  'not_exists',
  'type_mismatch',
  'exists'
);

create or replace function pg_temp.type_has_attribute(
  schema_name text,
  type_name text,
  attr pg_temp.attr
) returns pg_temp.attr_existence as $$
  select
    case
      when exists (
        select from information_schema.attributes
        where udt_schema = schema_name
          and udt_name = type_name
          and attribute_name = attr.name
          and data_type = attr.type
      ) then 'exists'::pg_temp.attr_existence
      when exists (
        select from information_schema.attributes
        where udt_schema = schema_name
          and udt_name = type_name
          and attribute_name = attr.name
          and data_type != attr.type
      ) then 'type_mismatch'::pg_temp.attr_existence
      else 'not_exists'::pg_temp.attr_existence
    end;
$$ language sql stable security invoker;

create or replace function pg_temp.escape_type(
  type_name text
) returns text as $$
  select array_to_string(array_agg(quote_ident(part)), '.') from unnest(parse_ident(type_name)) part;
$$ language sql immutable security invoker;

create or replace function pg_temp.add_attribute_if_not_exists(
  schema_name text,
  type_name text,
  attr pg_temp.attr
) returns void as $$
begin
  case pg_temp.type_has_attribute(schema_name, type_name, attr)
    when 'not_exists' then
      execute format('alter type %I.%I add attribute %I %s', schema_name, type_name, attr.name, attr.type);
    when 'type_mismatch' then
      execute format('alter type %I.%I alter attribute %I type %s', schema_name, type_name, attr.name, attr.type);
    else
      raise notice 'Attribute "%.% (% %)" exists, skipping', schema_name, type_name, attr.name, attr.type;
  end case;
end
$$ language plpgsql volatile security invoker;

create or replace function pg_temp.create_type_if_not_exists(
  qualified_name text,
  variadic attrs pg_temp.attr[]
) returns void as $$
declare
attr pg_temp.attr;
schema_name text = (parse_ident(qualified_name))[1];
type_name text = (parse_ident(qualified_name))[2];
begin
  assert array_length(parse_ident(qualified_name), 1) = 2, 'Must pass a schema qualified type name.';
  if not exists (
    select from pg_catalog.pg_type
    where typnamespace = schema_name::regnamespace
      and typname = type_name
  ) then
    execute format('create type %I.%I as ()', schema_name, type_name);
  else
    raise notice 'Type "%.%" exists, skipping', schema_name, type_name;
  end if;
  foreach attr in array attrs loop
    perform pg_temp.add_attribute_if_not_exists(schema_name, type_name, attr);
  end loop;
end
$$ language plpgsql volatile security invoker;

create or replace function pg_temp.add_value_if_not_exists(
  schema_name text,
  type_name text,
  vlue text
) returns void as $$
begin
  execute format('alter type %I.%I add value if not exists %L', schema_name, type_name, vlue);
end
$$ language plpgsql volatile security invoker;

create or replace function pg_temp.create_enum_if_not_exists(
  qualified_name text,
  variadic vlues text[]
) returns void as $$
declare
vlue text;
schema_name text = (parse_ident(qualified_name))[1];
type_name text = (parse_ident(qualified_name))[2];
begin
  assert array_length(parse_ident(qualified_name), 1) = 2, 'Must pass a schema qualified type name.';
  execute format('create type %I.%I as enum ()', schema_name, type_name);
exception when others then
  raise notice 'Type "%.%" exists, skipping', schema_name, type_name;
  foreach vlue in array vlues loop
    perform pg_temp.add_value_if_not_exists(schema_name, type_name, vlue);
  end loop;
end
$$ language plpgsql volatile security invoker;
