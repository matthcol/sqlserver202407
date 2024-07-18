select * from person where id = 767303;
insert into movie (title, year) values ('Dune: Part Two', 2024);
select * from movie where year >= 2020 order by year, title;

select * from person where name like 'Jean-Claude%';
select 
	a.name,
	m.year,
	m.title,
	pl.role
from 
	person a
	join play pl on a.id = pl.actor_id
	join movie m on pl.movie_id = m.id
where 
	a.name = 'Jean-Claude Van Damme'
order by m.year, m.title;


create or alter view v_movie_director as
select 
	m.id
	, m.title
	, m.year
	, m.director_id
	, d.name
from 
	movie m 
	left join person d on m.director_id = d.id
;

select *
from v_movie_director
where year = 1983
order by title;

select *
from v_movie_director
where year = 2024
order by title;

insert into movie (title, year) values ('Furiosa: A Mad Max Saga', 2024);

select *
from v_movie_director
where year = 2024
order by title;

create or alter view v_movie_1980s as
select * 
from movie
where year between 1980 and 1989;

select * from v_movie_1980s
order by year, title;

-- indexes
-- implicit: primary key, unique
select * from person where id = 241;
select * from person where name = 'Jean-Claude Van Damme';
-- cost: index unique => log(n)
-- n = 1024            => cost = 10
-- n ~= 1_000_000      => cost = 20
-- n ~= 1_000_000_000  => cost = 30

create index idx_movie_title on movie(title);
create index idx_person_name on person(name);

select * from person where name = 'Clint Eastwood';

-- integrity constraint

-- NULL or NOT NULL

-- Impossible d'insérer la valeur NULL dans la colonne 'year', table 'dbmovie.dbo.movie'. Cette colonne n'accepte pas les valeurs NULL. Échec de INSERT.
-- insert into movie (title) values ('Despicable Me 4');

-- KEYS: Primary Key, Foreign Key, Unique Key
-- Primary Key => clause Identity, auto generated
-- Foreign Key

select * from v_movie_director where year = 2024;
select * from person where name like 'Denis Villeneuve';
select * from v_movie_director where name like 'Denis Villeneuve';
update movie set director_id = 898288 where id = 8079249;
select * from v_movie_director where year = 2024;

select max(id) from person; -- 11903873
-- L'instruction UPDATE est en conflit avec la contrainte FOREIGN KEY "FK_MOVIE_DIRECTOR". Le conflit s'est produit dans la base de données "dbmovie", table "dbo.person", column 'id'.
-- update movie set director_id = 20000000  where id = 8079249;

-- unique
-- movie inserted twice
-- Violation de la contrainte UNIQUE KEY « uniq_movie ». Impossible d'insérer une clé en double dans l'objet « dbo.movie ». Valeur de clé dupliquée : (Furiosa: A Mad Max Saga, 2024).
-- insert into movie (title, year) values ('Furiosa: A Mad Max Saga', 2024);

-- check
-- L'instruction INSERT est en conflit avec la contrainte CHECK "chk_movie_year". Le conflit s'est produit dans la base de données "dbmovie", table "dbo.movie", column 'year'.
-- insert into movie (title, year) values ('no movie', 1789);

alter table have_genre add constraint uniq_movie_genre UNIQUE (movie_id, genre);
-- NB: fail if there are already duplicated entries
select * from v_movie_director where year = 2024;
insert into have_genre (movie_id, genre) values (8079249, 'Action');
insert into have_genre (movie_id, genre) values (8079249, 'Drama');
insert into have_genre (movie_id, genre) values (8079249, 'Drama');

select * from have_genre where movie_id = 8079249;
delete from have_genre where movie_id = 8079249;
ALTER TABLE have_genre DROP CONSTRAINT uniq_movie_genre;

-- Types
-- https://learn.microsoft.com/fr-fr/sql/t-sql/data-types/data-types-transact-sql?view=sql-server-ver16


create table price (
	id integer identity,
	name varchar(20),
	price decimal(5,2), -- exact
	price2 float, -- aproximative
	constraint pk_price primary key(id)
);

insert into price (name, price, price2) values ('1 place adulte', 12.5, 12.5);
insert into price (name, price, price2) values ('1 place étudiant', 8.1, 8.1);
select * from price;

select 
	name, 
	price,
	2*price as price_2p,
	3*price as price_3p,
	str(price2, 18, 16) as price2,
	str(2*price2, 18, 16) as price2_2p,
	str(3*price2, 18, 16) as price2_3p
from price;

-- types textes et classement (collation)
select * from sys.databases;
-- collation: French_CI_AS 
--  CI: Case Insensitive
--  CS: Case Sensitive
select * from movie where title like 'dune%'; -- Dune: Part Two
--  AS: Accent Sensitive
--  AI: Accent Insensitive
select * from person where name like 'zoe%'; -- 14 Zoe (no accent)
select * from person where name like 'zoë%'; -- 4 Zoë

-- case (CI/CS) + accent (CI/CS): =, <>, like

select LEN('Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch');

-- sort
create table city(
	id bigint identity,
	name varchar(100),
	constraint pk_city primary key(id)
);

-- french: tri ne considère pas les accents, ç, œ
-- é, è, ë, ê => e
-- ç => c
-- œ => oe
insert into city (name) values ('Nîmes');
insert into city (name) values ('Nice');
insert into city (name) values ('Niort');
insert into city (name) values ('albi');
insert into city (name) values ('zermezeele');
insert into city (name) values ('Åre');

select * from city order by name;

-- encoding: ascii, latin1/ISO-8859-1, ISO-8859-15, CP1252/ANSI, Unicode (UTF-8, UTF-16, UTF-32)
select '🍾';

SELECT name, description
FROM fn_helpcollations();

SELECT name, description
FROM fn_helpcollations()
WHERE name like 'French%';

-- collation de stockage: French_CI_AS
-- collation de recherche: French_CI_AI
select * from person where name like 'zoe%' collate French_CI_AI; -- 14+4=18

select name from city order by name;  -- Åre with letter A
select name from city order by name collate Finnish_Swedish_CI_AS; -- Åre after z

select name from (
	values ('mano'), ('mañana'), ('matador')
) as words_es(name)
order by name; -- mañana, mano, matador (not ok for spanish)

select name from (
	values ('mano'), ('mañana'), ('matador')
) as words_es(name)
order by name collate modern_spanish_ci_as;  -- mano, mañana, matador