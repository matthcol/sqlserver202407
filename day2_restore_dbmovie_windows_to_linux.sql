-- https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-database-to-a-new-location-sql-server?view=sql-server-ver16
USE [master]

RESTORE DATABASE [dbmovie] 
FROM  DISK = N'/tmp/dbmovie_cmp_20240717170145.bak' 
WITH  FILE = 1,  
MOVE N'dbmovie' TO N'/var/opt/mssql/data/dbmovie.mdf',  
MOVE N'dbmovie_log' TO N'/var/opt/mssql/data/dbmovie_log.ldf',  NOUNLOAD,  STATS = 5
GO

select * from sys.databases;
