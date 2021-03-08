
create table public.criteria (
  id serial primary key,
  pattern text not null,
  label text not null
);

create table public.passwds (
    id serial primary key,
    value text
);

create schema results;
 
create table public.results(
    id serial primary key,
    result json not null
);

create role authenticator noinherit login password 'mysecretpassword';
create role anon nologin;
create role paudit nologin;
grant paudit to authenticator;
grant anon to authenticator;

GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO authenticator;
GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO anon;
grant usage, select on sequence public.results_id_seq to anon;



