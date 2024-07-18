-- backup complet: data + journalisation
BACKUP DATABASE dbmovie 
	TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\dbmovie_cmp.bak' 
	WITH 
		NOFORMAT, 
		NOINIT,  
		NAME = N'dbmovie-Full Database Backup', 
		SKIP, 
		NOREWIND, 
		NOUNLOAD,  
		STATS = 10
;

-- autre emplacement
BACKUP DATABASE dbmovie 
	TO  DISK = N'C:\backup\dbmovie_cmp.bak' 
	WITH NOFORMAT, NOINIT,  NAME = N'dbmovie-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10

-- NOINIT: ajoute les backups dans le même fichier
-- INIT: !!!! écrase le fichier backup précédent (peut etre suffisant si backup infra: VM ou disk) 

BACKUP DATABASE dbmovie 
	TO  DISK = N'C:\backup\dbmovie_cmp.bak' 
	WITH INIT,  NAME = N'dbmovie-Full Database Backup';

-- backup avec tag de date (ou datetime)
DECLARE @backup_file varchar(150);
select @backup_file = concat(
		'C:\backup\dbmovie_cmp_', 
		replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', ''),
		'.bak'
		);
BACKUP DATABASE dbmovie 
	TO  DISK = @backup_file
	WITH NAME = N'dbmovie-Full Database Backup';
--
select 
	replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', '');
select concat(
		'C:\backup\dbmovie_cmp_', 
		replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', ''),
		'.bak'
		);

-- incident
drop table play;
use master;
-- base offline
alter database dbmovie set offline; -- gentil mais il faut attendre
alter database dbmovie set offline WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE dbmovie 
FROM  DISK = N'C:\backup\dbmovie_cmp_20240717115204.bak' 
WITH  REPLACE;

RESTORE DATABASE dbmovie 
FROM  DISK = N'C:\backup\dbmovie_cmp_20240717115204.bak' 
WITH  REPLACE, STATS=10; -- ~ 10 messages intermédiaires (tous les ~ 10%)

RESTORE DATABASE dbmovie 
FROM  DISK = N'C:\backup\dbmovie_cmp_20240717115204.bak' 
WITH  REPLACE, STATS=50; -- 2 messages intermédiaires

-- auto si succès: alter database dbmovie set online;

-- backup complet à 2024-07-17T13:39:53.7627299+02:00
use dbmovie;
-- 13h42: 10 films soleil% de 2025 (script flood)
-- 13h44:
update movie set synopsis = 'film sur le soleil qui se lève puis se couche...'
where title like 'soleil%' and year = 2025;
-- 13h47
select count(*) from play where movie_id % 2 = 0;
delete from play where movie_id % 2 = 0;  -- 37568
select count(*) from play; -- 28979

-- sauvegarde log only
BACKUP LOG dbmovie 
TO  DISK = N'C:\backup\dbmovie_log_20240717135253.bak' 
WITH NOFORMAT, NOINIT,  
	NAME = N'dbmovie-Log Backup', 
	SKIP, NOREWIND, NOUNLOAD,  STATS = 10
;

-- verifier log tronqués
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

-- 13h57:
-- ajouter 10 films vacances de 2026 (script flood)

alter database dbmovie set offline with rollback immediate;
alter database dbmovie set online;
-- ou
ALTER DATABASE dbmovie SET  RESTRICTED_USER WITH NO_WAIT; -- accès admin only
-- ALTER DATABASE dbmovie SET  SINGLE_USER WITH NO_WAIT; -- seul utilisateur (admin, 1)

-- backup des toutes dernieres jounalisation avant restauration
BACKUP LOG dbmovie
TO  DISK = N'C:\backup\dbmovie_log_last.bak' 
WITH  NO_TRUNCATE , NOFORMAT, NOINIT,  
	NAME = N'dbmovie-Last Log Backup', 
	SKIP, NOREWIND, NOUNLOAD,  
	NORECOVERY ,  -- => base bascule en mode restauration (STANDBY: lecture seule)
	STATS = 10
;

RESTORE DATABASE dbmovie
	FROM  DISK = N'C:\backup\dbmovie_cmp_20240717133953.bak' 
	WITH  NORECOVERY,  STATS = 5;
RESTORE LOG dbmovie 
	FROM  DISK = N'C:\backup\dbmovie_log_20240717135253.bak' 
	WITH  NORECOVERY,  STATS = 5;
RESTORE LOG dbmovie 
	FROM  DISK = N'C:\backup\dbmovie_log_last.bak' 
	WITH  STATS = 5;


ALTER DATABASE dbmovie SET  MULTI_USER WITH NO_WAIT; -- all users

-- check last data is here
use dbmovie;
select * from movie where year = 2026;


alter database dbmovie set offline with rollback immediate;

-- restauration partielle
use master;
RESTORE DATABASE dbmovie
	FROM  DISK = N'C:\backup\dbmovie_cmp_20240717133953.bak' 
	WITH  NORECOVERY,  STATS = 5;
RESTORE LOG dbmovie 
	FROM  DISK = N'C:\backup\dbmovie_log_20240717135253.bak' 
	WITH  STATS = 5; -- last one (pas de clause norecovery)

use dbmovie;
select * from movie where year >= 2025; -- soleil mais pas vacances
select count(*) from play; -- ok: missing half

-- PITR: Point In Time Recovery
-- incident logiciel: 
-- 13h44 ok (ajout synopsis), 
-- 13h47 ko (delete 1/2 table play)
use master;
alter database dbmovie set offline with rollback immediate;

RESTORE DATABASE dbmovie
	FROM  DISK = N'C:\backup\dbmovie_cmp_20240717133953.bak' 
	WITH  NORECOVERY,  REPLACE, STATS = 5
;
RESTORE LOG dbmovie 
	FROM  DISK = N'C:\backup\dbmovie_log_20240717135253.bak' 
	WITH  STOPAT = '2024-07-17T13:45:00',  
		STATS = 5
;

use dbmovie;
select * from movie where year >= 2025; -- soleil mais pas vacances
select count(*) from play; -- ok: all

-- exploitation des journaux avec numéro de transaction: LSN
select 
	name,
	physical_name,
	differential_base_lsn,
	differential_base_time
from sys.master_files
where name like 'dbmovie';
-- dbmovie	C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbmovie.mdf	
-- 41000003141500001	2024-07-17 11:39:53.700

select 
	name,
	physical_name,
	differential_base_lsn,
	differential_base_time,
	create_lsn,
	drop_lsn,
	read_only_lsn,
	read_write_lsn
from sys.database_files;

-- dbmovie	C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbmovie.mdf	41000003141500001	2024-07-17 11:39:53.700	NULL	NULL	NULL	NULL
-- dbmovie_log	C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbmovie_log.ldf	NULL	NULL	NULL	NULL	NULL	NULL

-- LSN des backups: table msdb.dbo.backupset
SELECT bs.database_name,
    backuptype = CASE 
        WHEN bs.type = 'D' AND bs.is_copy_only = 0 THEN 'Full Database'
        WHEN bs.type = 'D' AND bs.is_copy_only = 1 THEN 'Full Copy-Only Database'
        WHEN bs.type = 'I' THEN 'Differential database backup'
        WHEN bs.type = 'L' THEN 'Transaction Log'
        WHEN bs.type = 'F' THEN 'File or filegroup'
        WHEN bs.type = 'G' THEN 'Differential file'
        WHEN bs.type = 'P' THEN 'Partial'
        WHEN bs.type = 'Q' THEN 'Differential partial'
        END + ' Backup',
    CASE bf.device_type
        WHEN 2 THEN 'Disk'
        WHEN 5 THEN 'Tape'
        WHEN 7 THEN 'Virtual device'
        WHEN 9 THEN 'Azure Storage'
        WHEN 105 THEN 'A permanent backup device'
        ELSE 'Other Device'
        END AS DeviceType,
    bms.software_name AS backup_software,
    bs.recovery_model,
    bs.compatibility_level,
    BackupStartDate = bs.Backup_Start_Date,
    BackupFinishDate = bs.Backup_Finish_Date,
    LatestBackupLocation = bf.physical_device_name,
    backup_size_mb = CONVERT(DECIMAL(10, 2), bs.backup_size / 1024. / 1024.),
    compressed_backup_size_mb = CONVERT(DECIMAL(10, 2), bs.compressed_backup_size / 1024. / 1024.),
    database_backup_lsn, -- For tlog and differential backups, this is the checkpoint_lsn of the FULL backup it is based on.
    checkpoint_lsn,
    begins_log_chain,
    bms.is_password_protected
FROM msdb.dbo.backupset bs
LEFT JOIN msdb.dbo.backupmediafamily bf
    ON bs.[media_set_id] = bf.[media_set_id]
INNER JOIN msdb.dbo.backupmediaset bms
    ON bs.[media_set_id] = bms.[media_set_id]
WHERE bs.backup_start_date > DATEADD(MONTH, - 2, sysdatetime()) --only look at last two months
ORDER BY bs.database_name ASC,
    bs.Backup_Start_Date DESC;

-- convert datetime in LSN
select * from sys.databases;
EXEC sys.sp_cdc_enable_db;
SELECT sys.fn_cdc_map_time_to_lsn('smallest greater than','2024-07-17T12:00:00');
-- exploite la table: select * from cdc.lsn_time_mapping;


-- Mode de récupération: 
-- https://learn.microsoft.com/fr-fr/sql/relational-databases/backup-restore/recovery-models-sql-server?view=sql-server-ver16
-- propriété de la base: simple ou full (dtabase -> propriétés -> option)
ALTER DATABASE [dbmovie] SET RECOVERY SIMPLE WITH NO_WAIT;

-- ajout 1000 films vacances à la neige en 2028

-- backup complet

-- ajout 1000 films vacances dans l''espace en 2029

alter database dbmovie set offline with rollback immediate;

RESTORE DATABASE dbmovie
	FROM  DISK = N'C:\backup\dbmovie_cmp_20240717160603.bak' 
	WITH  STATS = 5
;

use dbmovie;
DBCC SHRINKFILE (N'dbmovie_log');

-- restore avec choix du fichier et mode stand by
use master;
alter database dbmovie set offline with rollback immediate;
RESTORE DATABASE dbmovie 
	FILE = N'dbmovie' 
	FROM  DISK = N'C:\backup\dbmovie_cmp_20240717160603.bak' 
	WITH STATS = 10, 
		STANDBY = 'C:\backup\stanby.stdf'
;

-- check with users movier, moview read-only database
-- delete: Échec de la mise à jour de la base de données "dbmovie" car celle-ci est en lecture seule.
alter database dbmovie set offline with rollback immediate;
alter database dbmovie set online;
restore database dbmovie with recovery;

-- check with user moview: 
-- insert into person(name) values ('Matthias');
-- ok


DECLARE @backup_file varchar(150);
select @backup_file = concat(
		'C:\backup\dbmovie_cmp_', 
		replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', ''),
		'.bak'
		);
BACKUP DATABASE dbmovie 
	TO  DISK = @backup_file 
	WITH  RETAINDAYS = 5, 
		NAME = N'dbmovie-Full Database Backup',
		NOSKIP,  STATS = 10
;
go

-- options (NO)SKIP, (NO)INIT
-- Le média du support 'C:\backup\dbmovie_cmp_20240717165029.bak' expire le juil 22 2024  4:50:29:000PM et ne peut pas être remplacé.
-- empeche la perte de la sauvegarde si delai de retention
DECLARE @backup_file varchar(150) = 'C:\backup\dbmovie_cmp_20240717165029.bak';
BACKUP DATABASE dbmovie 
	TO  DISK = @backup_file 
	WITH  RETAINDAYS = 5, 
		NAME = N'dbmovie-Full Database Backup',
		NOSKIP, INIT,  STATS = 10
;
go

-- refaire un normal
DECLARE @backup_file varchar(150);
select @backup_file = concat(
		'C:\backup\dbmovie_cmp_', 
		replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', ''),
		'.bak'
		);
BACKUP DATABASE dbmovie 
	TO  DISK = @backup_file 
	WITH  RETAINDAYS = 5, 
		NAME = N'dbmovie-Full Database Backup',
		NOSKIP,  STATS = 10
;
go

-- idem avec compression: 32M => 6M
DECLARE @backup_file varchar(150);
select @backup_file = concat(
		'C:\backup\dbmovie_cmp_', 
		replace(
		replace(
			replace(convert(varchar, getdate(), 120), '-', ''),
			' ', ''),
		':', ''),
		'.bak'
		);
BACKUP DATABASE dbmovie 
	TO  DISK = @backup_file 
	WITH  RETAINDAYS = 5, 
		COMPRESSION,
		NAME = N'dbmovie-Full Database Backup',
		NOSKIP,  STATS = 10
;
go

-- encryption
