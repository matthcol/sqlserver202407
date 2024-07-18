begin transaction;
insert into movie (title, year) values ('Deadpool and Wolverine', 2024);
-- rollback;
-- dba: dbmovie offline with rollback immediate
commit;
-- The connection is broken and recovery is not possible.  The connection is marked by the server as unrecoverable.  No attempt was made to restore the connection.
