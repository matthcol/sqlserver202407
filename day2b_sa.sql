-- code stocké
-- types et fonctions customs
-- procedures
-- triggers: procedure déclenché sur un evenement du DML (insert, update, delete, ...) ou autre

delete from have_genre;
select count(*) from have_genre;
-- cmd or powershell:  sqlcmd -A -d dbmovie -i .\05-data-genres.sql
select count(*) from have_genre;

-- synonyms: multi base and/or multi schema
-- https://learn.microsoft.com/en-us/sql/relational-databases/synonyms/create-synonyms?view=sql-server-ver16


-- user, login, role, privileges
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/security/authentication-access/create-a-database-user?view=sql-server-ver16
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-ver16
select 
	CURRENT_USER, user_name(), -- alias => dbo (database owner)
	original_login() -- login used to connect to the db WIN22\Administrateur
;

select * from sys.databases; -- sys = user + schema
select * from INFORMATION_SCHEMA.TABLES order by table_type;
select * from sys.sql_logins; -- list of logins
select * from sys.database_principals; -- list of users (current db)

