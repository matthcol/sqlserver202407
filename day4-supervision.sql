-- session utilisateur
exec sp_who;
exec sp_who2; -- more detail
exec sp_who 'movie';

select * from sys.sysprocesses where loginame = 'movie';  -- spid: 66
-- https://learn.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql?view=sql-server-ver16
kill 66;


-- MISC
exec sp_databases;
SELECT SERVERPROPERTY('EDITION');

-- sessions avec verrrous (locks)
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/performance-monitor/sql-server-locks-object?view=sql-server-ver16

use dbmovie;
-- session 0
insert into movie (title, year) values ('Deadpool and Wolverine', 2024);
insert into movie (title, year) values ('Dune: Part Two', 2024);
select id, title, year, duration, director_id from movie 
where title in (
	'Deadpool and Wolverine',  -- id: 8182265
	'Dune: Part Two' -- id: 8079249
);

-- session 1: user movie avec sqlcmd
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED
begin transaction;
select @@SPID; -- 70
select id, title, year, duration, director_id from movie where title ='Deadpool and Wolverine';
update movie set duration = 127 where id = 8182265;
select id, title, year, duration, director_id from movie where title ='Deadpool and Wolverine';
select id, title, year, duration, director_id from movie where title ='Dune: Part Two';
update movie set duration = 180 where id = 8079249;
select id, title, year, duration, director_id from movie where title ='Dune: Part Two';
-- rollback;
commit;
go
select id, title, year, duration, director_id from movie 
where title in (
	'Deadpool and Wolverine',  -- id: 8182265
	'Dune: Part Two' -- id: 8079249
);


-- session 2: user movie avec sqlcmd (bad idea: ordre des modifs croisées)
begin transaction;
select @@SPID; -- 70
select id, title, year, duration, director_id from movie where title ='Dune: Part Two';
update movie set director_id = 2 where id = 8079249;
select id, title, year, duration, director_id from movie where title ='Deadpool and Wolverine';
update movie set director_id = 1 where id = 8182265; -- bloqué par l'update session 1 = même ligne

-- session 2bis: user movie avec sqlcmd (bad idea: same order)
begin transaction;
select @@SPID; -- 70
select id, title, year, duration, director_id from movie where title ='Deadpool and Wolverine';
update movie set director_id = 1 where id = 8182265; -- bloqué par l'update session 1 = même ligne
select id, title, year, duration, director_id from movie where title ='Dune: Part Two';
update movie set director_id = 2 where id = 8079249;
select id, title, year, duration, director_id from movie where title ='Dune: Part Two';
commit;
select id, title, year, duration, director_id from movie 
where title in (
	'Deadpool and Wolverine',  -- id: 8182265
	'Dune: Part Two' -- id: 8079249
);




-- supervision des locks
select * from sys.dm_tran_locks
where request_session_id in (77, 78);

-- NB: resource_type = DATABASE, request_mode = S: verrou de ssesion sur 1 base


DBCC useroptions

-- ISOLATION des transactions: default: READ COMMITED (with db property READ_COMMITTED_SNAPSHOT OFF)
select name, is_read_committed_snapshot_on from sys.databases where name = 'dbmovie'; -- 0: OFF
use master;
alter database dbmovie set offline with rollback immediate;  
alter database dbmovie set READ_COMMITTED_SNAPSHOT ON;
alter database dbmovie set online;  
select name, is_read_committed_snapshot_on from sys.databases where name = 'dbmovie'; -- 1: ON


-- maintenance
-- Plan de maintenance
-- SQL Server Agent
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/maintenance-plans/create-a-maintenance-plan-maintenance-plan-design-surface?view=sql-server-ver16
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/maintenance-plans/create-a-maintenance-plan?view=sql-server-ver16

-- 1. plan de maintenance avec assistant => crée 1 package appelé par le scheduler
-- 2. plan de maintenance en TSQL: job only sur le scheduler

-- NB: Schrink (auto)
ALTER DATABASE [dbmovie] SET AUTO_SHRINK ON WITH NO_WAIT


-- indexes => rebuild (bloquant), reorganize (non bloquant)
-- https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-index-transact-sql?view=sql-server-ver16
-- utile pour table avec beaucoup de mouvement (update, delete, truncate)
use dbmovie;
alter index idx_person_name on person rebuild;
alter index idx_person_name on person reorganize;

-- type d'index
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/indexes/indexes?view=sql-server-ver16

-- 1. Clustered vs non clustered
-- chaque table nécessite un inde de type clustered (primary key ou alt.)
select * from have_genre where genre = 'Drama'; -- table scan (par numero de ligne)
select * from movie where duration > 120; -- index clustered pk_movie

-- 2. Types d'indexes:

select * from person where name like 'Clint%'; -- index idx_person_name puis pk_person (opt)
select * from person where name like 'C%'; -- index clustered pk_person (pas assez de lettres)
select * from person where name like '%Eastwwod'; -- pas efficache

declare @name varchar(30) = 'Clint Eastwood';
select right(@name, len(@name) - charindex(' ', @name));

use dbmovie;
go
drop function dbo.endname;
go
create function dbo.endname(@p_name varchar(150))
returns varchar(150)
with schemabinding -- NB: to be deterministic
as
begin
	declare @result varchar(150);
	select @result = right(@p_name, len(@p_name) - charindex(' ', @p_name));
	return @result;
end;
go

select dbo.endname('Clint Eastwood');
select name, dbo.endname(name) from person where year(birthdate) = 1930;

alter table person add p_endname as dbo.endname(name);
select name, p_endname from person where year(birthdate) = 1930;

-- https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/deterministic-and-nondeterministic-functions?view=sql-server-ver16
SELECT OBJECTPROPERTY(OBJECT_ID('dbo.endname'), 'IsDeterministic');
-- alter table person drop column p_endname;

create index idx_person_endname on person(p_endname); -- ok si fonction deterministe

select * from person where dbo.endname(name) = 'Eastwood'; -- no index
select * from person where p_endname = 'Eastwood'; -- par index: idx_person_endname

drop index idx_person_endname on person;
alter table person drop column p_endname;
alter table person add p_endname as right(name, len(name) - charindex(' ', name));
create index idx_person_endname on person(p_endname);

select * from person where p_endname = 'Eastwood';
insert into person(name) values ('Shawn Levy'); -- id = 11903875
select * from person where name like 'Shawn Levy'; 
update person set name = 'Unknown Unknown' where id = 11903875;
select * from person where id = 11903875;

-- NB1: autres indexes: spatiaux, hash, xml, Texte intégral
-- NB2: indexer une clé étrangère
select m.id, m.title, m.year, m.director_id, d.name
from movie m left join person d on m.director_id = d.id
where m.year = 1982; -- index pk_person


select m.id, m.title, m.year, m.director_id, d.name
from movie m left join person d on m.director_id = d.id
where d.name = 'Clint Eastwood'; -- filtre table person puis full scan sur table movie

create index idx_movie_director on movie(director_id);

select m.id, m.title, m.year, m.director_id, d.name
from movie m left join person d on m.director_id = d.id
where d.name = 'Clint Eastwood'; -- index clé étrangere efficace


-- statistiques : influer le plan d'execution, choix des algos, passer par les index ou pas
-- https://learn.microsoft.com/fr-fr/sql/t-sql/database-console-commands/dbcc-show-statistics-transact-sql?view=sql-server-ver16

DBCC SHOW_STATISTICS (movie, idx_movie_director);

-- https://learn.microsoft.com/fr-fr/sql/relational-databases/statistics/view-statistics-properties?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-stats-histogram-transact-sql?view=sql-server-ver16


use dbmovie;
go
SELECT 
	object_id
	,name AS statistics_name  
    ,stats_id  
    ,auto_created  
    ,user_created  
    ,no_recompute  
    ,has_filter  
    ,filter_definition  
-- using the sys.stats catalog view  
FROM sys.stats  
WHERE 
	-- name = 'stat_year' 
	object_id = OBJECT_ID('movie');  
GO

SELECT * FROM sys.dm_db_stats_histogram(OBJECT_ID('movie'), 8); -- 8 = statid (idx_movie_director)


-- uopdate stat
update statistics movie(idx_movie_director) with fullscan;
update statistics movie(idx_movie_director) with sample 10 PERCENT;

-- all stats
EXEC sp_updatestats; 

-- creer une statistique
CREATE STATISTICS [stat_year] ON [dbo].[movie]([year]);

-- compter les tables

select count(*) from INFORMATION_SCHEMA.tables where table_type = 'BASE TABLE'; -- 13
select * from INFORMATION_SCHEMA.tables 
where table_type = 'BASE TABLE';


-- Autres points à explorer
-- server logs: limite, rotation, delai de garde
-- table temporaire: table commençant par # (privé) ou ## (public) dans la base tmpdb
-- base en memoire (tables): rapidité 
-- graphe: équivalent contrainte intégrité de clé étrangère
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/graphs/sql-graph-architecture?view=sql-server-ver16


