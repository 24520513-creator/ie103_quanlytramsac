USE master;
GO

/*
Create C:\Backup first, or change the path below for the demo machine.

BACKUP DATABASE EV_Charging_System
TO DISK = 'C:\Backup\EV_Charging_System.bak'
WITH INIT, FORMAT, STATS = 10;

Safe restore example:
1. Backup the existing database first.
2. Close active connections.
3. Adjust MOVE file paths for the SQL Server machine.

RESTORE DATABASE EV_Charging_System_RestoreDemo
FROM DISK = 'C:\Backup\EV_Charging_System.bak'
WITH FILE = 1,
     MOVE 'EV_Charging_System' TO 'C:\Backup\EV_Charging_System_RestoreDemo.mdf',
     MOVE 'EV_Charging_System_log' TO 'C:\Backup\EV_Charging_System_RestoreDemo_log.ldf',
     STATS = 10;
*/

PRINT N'12 - Backup/restore demo script. Read comments before running.';
GO
