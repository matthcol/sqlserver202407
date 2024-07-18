-- https://learn.microsoft.com/fr-fr/sql/database-engine/configure-windows/agent-xps-server-configuration-option?view=sql-server-ver16
sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Agent XPs', 1;  
GO  
RECONFIGURE  
GO