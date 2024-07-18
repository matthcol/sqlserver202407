select * from sys.databases;

-- https://learn.microsoft.com/fr-fr/sql/relational-databases/security/authentication-access/create-a-login?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-login-transact-sql?view=sql-server-ver16

use master;
select * from sys.sql_logins;
drop login movie;
create login movie with 
	password = 'Password@',
	default_database = dbmovie;
select * from sys.sql_logins;
use dbmovie;
create user movie for login movie;

-- sqlcmd -U movie
-- sqlcmd -U movie -d dbmovie
select db_name();
-- https://www.mssqltips.com/sqlservertutorial/196/information-schema-tables/
-- table_type: VIEW or BASE TABLE
SELECT * FROM INFORMATION_SCHEMA.TABLES;
select * from sys.sql_logins;
alter role db_owner add member movie; -- or use sp_addrolemember (old)

-- sqlcmd -U movie -i .\05-data-genres.sql

SELECT name, description
FROM fn_helpcollations();

select * from sys.databases;

-- password policy:
-- https://learn.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver16
-- on any base: master, dbmovie
CREATE LOGIN movieo WITH PASSWORD=N'Password@', DEFAULT_DATABASE=dbmovie;
CREATE LOGIN movier WITH PASSWORD=N'Password@', DEFAULT_DATABASE=dbmovie;
CREATE LOGIN moview WITH PASSWORD=N'Password@', DEFAULT_DATABASE=dbmovie;

alter login movieo with password='pASSWORDd#';

-- activer/desactiver user: Global => Security => Logins => sa (ou autre) => Status (enabled/disabled)
alter login sa disable;
alter login sa enable;

select * from sys.sql_logins;
select 
	name,
	is_disabled,
	default_database_name
from sys.sql_logins;

-- on base dbmovie
use dbmovie;
CREATE USER movieo FOR LOGIN movieo WITH DEFAULT_SCHEMA=dbo;
ALTER ROLE db_owner ADD MEMBER movieo;

CREATE USER movier FOR LOGIN movier WITH DEFAULT_SCHEMA=dbo;
ALTER ROLE db_datareader ADD MEMBER movier;

CREATE USER moview FOR LOGIN moview WITH DEFAULT_SCHEMA=dbo;
ALTER ROLE db_datareader ADD MEMBER moview;
ALTER ROLE db_datawriter ADD MEMBER moview;

-- sqlcmd -U movieo
-- sqlcmd -U movieo -d dbmovie
-- sqlcmd -U movier
-- sqlcmd -U moview
select title, year, synopsis from movie where year = 2024;
insert into movie (title, year) values ('Despicable 4', 2024);
update movie set synopsis = 'a movie with bad and ugly people' where title = 'Despicable 4';
delete from movie where title = 'Despicable 4';
drop table city;
create table mycity(a int);

CREATE LOGIN moviec WITH PASSWORD=N'Password@', DEFAULT_DATABASE=dbmovie;
CREATE USER moviec FOR LOGIN moviec WITH DEFAULT_SCHEMA=dbo;

SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- privileges DML
grant select on movie to moviec;

-- privileges DDL
grant create view to moviec;
grant alter on schema::dbo to moviec;
revoke alter on schema::dbo from moviec;
revoke create view from moviec;

revoke select on movie from moviec;
grant select on v_movie_current_year to moviec;

ALTER ROLE db_datareader DROP MEMBER movier;
grant select on schema::dbo to movier;
revoke select on schema::dbo from movier;
-- privilege transmissible:
grant select on schema::dbo to movier with grant option; 

-- as movier: ok
grant select on schema::dbo to moviec;

-- as dbo:
select * from v_movie_current_year;
insert into v_movie_current_year (title, year) values ('Despicable 4', 2024);
select * from v_movie_current_year;
update v_movie_current_year set synopsis = 'a movie with bad and ugly people' where title = 'Despicable 4';
select * from v_movie_current_year;
delete from v_movie_current_year where title = 'Despicable 4';
select * from v_movie_current_year;

select * from movie where title like 'Despicable%';
insert into v_movie_current_year (title, year) values ('Despicable', 2010);
select * from v_movie_current_year;
select * from movie where title like 'Despicable%';
delete from  v_movie_current_year where title like 'Despicable%';
select * from v_movie_current_year;
update v_movie_current_year set year = 2023 where title = 'Dune: Part Two';
select * from v_movie_current_year;
select * from movie where year = 2023;
update movie set year = 2024 where title = 'Dune: Part Two';
select * from v_movie_current_year;
delete from movie where title like 'Despicable%';

drop view v_movie_current_year;
create view v_movie_current_year as
	select title, year, synopsis 
	from movie 
	where year = YEAR(current_timestamp)
WITH CHECK OPTION;

select * from v_movie_current_year;
insert into v_movie_current_year (title, year) values ('Despicable 4', 2024);
-- ko: insert into v_movie_current_year (title, year) values ('Despicable', 2010);
-- ko: update v_movie_current_year set year = 2023 where title = 'Dune: Part Two';
update v_movie_current_year set synopsis = 'a movie with bad and ugly people' where title = 'Despicable 4';
select * from v_movie_current_year;
delete from v_movie_current_year where title = 'Despicable 4';
select * from v_movie_current_year;


revoke select on schema::dbo from moviec;
grant insert on v_movie_current_year to moviec;
grant update on v_movie_current_year(synopsis) to moviec;


drop view v_movie_current_year;
create view v_movie_current_year as
	select id, title, year, duration, synopsis, color, pg, poster_uri 
	from movie 
	where year = YEAR(current_timestamp)
WITH CHECK OPTION;

drop role movie_manager;
create role movie_manager  AUTHORIZATION dbo;
-- TODO: 1 - add in role privileges: select, insert, update (duration,synopsis,poster_uri, color, pg)
-- sur la vue v_movie_current_year
-- 2 - creer un utilisateur avec ce role et verifier les différents scenarios
grant select on v_movie_current_year to movie_manager;
grant insert on v_movie_current_year to movie_manager;
grant update on v_movie_current_year(synopsis,poster_uri, color, pg) to movie_manager;

CREATE LOGIN moviem WITH PASSWORD=N'Password@', DEFAULT_DATABASE=dbmovie;
CREATE USER moviem FOR LOGIN moviem WITH DEFAULT_SCHEMA=dbo;
ALTER ROLE data_manager ADD MEMBER moviem;
ALTER ROLE data_manager DROP MEMBER moviem;



select * from sys.database_permissions as pm
join sys.database_principals as pl on pm.grantee_principal_id = pl.principal_id where pl.name ='movie_manager';

-- grant select on schema::dbo to movie_manager;
-- select * from sys.database_permissions as pm
-- join sys.database_principals as pl on pm.grantee_principal_id = pl.principal_id where pl.name ='db_datareader';

-- NB: privilege EXECUTE sur code stocké

-- Fichiers:
-- database dbmovie:
-- File 1: data
--       dbmovie = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbmovie.mdf'
-- File 2: journaux de transaction
--       dbmovie_log = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbmovie.ldf'
-- NB: 1K = 2^10 = 1024
CREATE DATABASE dbmovie2
 ON  PRIMARY 
( NAME = N'dbmovie2', FILENAME = N'C:\data\dbmovie2.mdf' , SIZE = 32768KB , FILEGROWTH = 32768KB )
 LOG ON 
( NAME = N'dbmovie2_log', FILENAME = N'C:\data\dbmovie2_log.ldf' , SIZE = 32768KB , MAXSIZE = 512000KB , FILEGROWTH = 32768KB )
;

select * from sys.databases;

-- sqlcmd -A -d dbmovie2 -i .\01-tables.sql
-- sqlcmd -A -d dbmovie2 -i .\02-data-movie.sql
-- ...

-- https://learn.microsoft.com/fr-fr/sql/relational-databases/pages-and-extents-architecture-guide?view=sql-server-ver16

-- taille en pages
-- 1 page = 8 KB = 8 Ko (Byte = octet)
-- 2^3 * 2^10 octets

-- table master_files: liste des fichiers de base de données + logs (transverse)
select 
	name,
	physical_name,
	size as size_page,
	type_desc,
	size * 8 as sike_ko,
	size / 128 as size_mo,
	max_size as max_size_page,
	max_size / 128 as max_size_mo,
	cast(max_size as bigint) * 8 as max_size_ko
from sys.master_files
where name like 'dbmovie%';

-- units
-- K = 2^10 = 1024
-- M = 2^20 million
-- G = 2^30 milliard
-- T = 2^40
-- P = 2^50
-- E = 2^60 milliard de milliard
-- Z = 2^70
-- Y = 2^80

-- https://learn.microsoft.com/fr-fr/sql/relational-databases/pages-and-extents-architecture-guide?view=sql-server-ver16
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/databases/display-data-and-log-space-information-for-a-database?view=sql-server-ver16

-- table: sys.database_files 
use dbmovie2;
go
SELECT 
	db_id(),
	db_name(),
	file_id, 
	name, 
	type_desc, 
	physical_name, 
	size / 128.0 as size_mo, 
	max_size / 128.0 as max_size_mo,
	FILEPROPERTY(name, 'SpaceUsed') / 128.0 as size_used_mo,
	(size - FILEPROPERTY(name, 'SpaceUsed')) / 128.0 as size_free_mo
FROM sys.database_files; 

EXEC sp_spaceused;
go

EXEC sp_helpdb;
go

EXEC sp_helpdb dbmovie2;
go

-- only logs
DBCC SQLPERF(logspace) 


-- taille par tables
SELECT
  t.object_id,
  OBJECT_NAME(t.object_id) ObjectName,
  sum(u.total_pages) * 8 Total_Reserved_kb,
  sum(u.used_pages) * 8 Used_Space_kb,
  u.type_desc,
  max(p.rows) RowsCount
FROM
  sys.allocation_units u
  JOIN sys.partitions p on u.container_id = p.hobt_id

  JOIN sys.tables t on p.object_id = t.object_id

GROUP BY
  t.object_id,
  OBJECT_NAME(t.object_id),
  u.type_desc
ORDER BY
  Used_Space_kb desc,
  ObjectName;

-- LOB: large object => text, image, xml, varchar(n) n big (> 64Ko)
select title, year from movie where year = 1984; -- pas besoin du LOB avec les synopsis
select title, year, synopsis from movie where year = 1984; -- pour chaque ligne => LOB assoscié pour le synopsis

-- flood: 1 M de films Dune

delete from movie where year = 2025 and title like 'Dune %1'; -- delete 1/10: 100_000
-- C:\data\dbmovie2.mdf	192.000000	-0.007812	188.812500	3.187500
-- C:\data\dbmovie2_log.ldf	384.000000	500.000000	133.125000	250.875000

-- https://learn.microsoft.com/en-us/sql/relational-databases/databases/shrink-a-file?view=sql-server-ver16
DBCC SHRINKFILE (N'dbmovie2' , 0, TRUNCATEONLY)
-- 6	1	24168	4096	24160	24160

-- C:\data\dbmovie2.mdf	188.812500	-0.007812	188.812500	0.000000

DBCC SHRINKFILE (N'dbmovie2_log' , 150)
-- 6	2	19456	4096	19456	4096

-- C:\data\dbmovie2_log.ldf	152.000000	500.000000	0.835937	151.164062

DBCC SHRINKDATABASE(N'dbmovie2')
-- C:\data\dbmovie2.mdf	188.812500	-0.007812	188.812500	0.000000
-- C:\data\dbmovie2_log.ldf	32.000000	500.000000	0.367187	31.632812

-- taille table movie
-- 613577224	movie	183056	182816	IN_ROW_DATA	1931931
-- 677577452	play	4424	2216	IN_ROW_DATA	66547
-- 581577110	person	1672	1656	IN_ROW_DATA	49649
-- 613577224	movie	840	808	LOB_DATA	1931931
-- 709577566	have_genre	136	88	IN_ROW_DATA	3429
alter table movie rebuild; -- all indexes (clustered, non clustered)
-- 613577224	movie	179296	179008	IN_ROW_DATA	1931931
-- 677577452	play	4424	2216	IN_ROW_DATA	66547
-- 581577110	person	1672	1656	IN_ROW_DATA	49649
-- 613577224	movie	840	808	LOB_DATA	1931931
-- 709577566	have_genre	136	88	IN_ROW_DATA	3429
