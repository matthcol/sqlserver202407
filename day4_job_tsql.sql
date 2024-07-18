USE [msdb];
GO

EXEC [dbo].[sp_add_job] @job_name = N'Database_Shrink',
                        @enabled = 1,
                        @description = N'Database Shrink',
						@owner_login_name=N'WIN22\Administrateur';
GO

EXEC [dbo].[sp_add_jobstep] @job_name = N'Database_Shrink',
                            @step_name = N'Database Shrink_1',
                            @subsystem = N'TSQL',
							@database_name = N'dbmovie',
                            @command = N'USE [dbmovie];
GO
DBCC SHRINKDATABASE(N''dbmovie'')
GO
';
GO

-- Creates a schedule named RunOnce that executes every day when the time on the server is 23:30.
EXEC [dbo].[sp_add_schedule] @schedule_name = N'RunWeekly',
                             @freq_type = 8, -- weekly
                             @freq_interval = 1, -- dimanche
							 @freq_recurrence_factor = 1, -- toutes les 1 semaine
                             @active_start_time = 010500;
GO
-- Attaches the RunOnce schedule to the job HistoryCleanupTask_1.
EXEC [dbo].[sp_attach_schedule] @job_name = N'Database_Shrink',
                                @schedule_name = N'RunWeekly';
GO

EXEC msdb.dbo.sp_add_jobserver @job_name = N'Database_Shrink', @server_name = N'WIN22'
GO
