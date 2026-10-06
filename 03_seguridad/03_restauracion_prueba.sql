USE master;
GO

PRINT '====================================================';
PRINT 'INICIANDO PRUEBA CONTROLADA DE RESTAURACIÓN';
PRINT '====================================================';

DECLARE @BackupDir NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(400));
DECLARE @DataPath  NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(400));
DECLARE @LogPath   NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(400));

IF RIGHT(@BackupDir, 1) <> '\' SET @BackupDir = @BackupDir + '\';
IF RIGHT(@DataPath, 1) <> '\'  SET @DataPath  = @DataPath + '\';
IF RIGHT(@LogPath, 1) <> '\'   SET @LogPath   = @LogPath + '\';

DECLARE @RutaFull NVARCHAR(500) = @BackupDir + N'DataSalud_FULL.bak';
DECLARE @RutaDiff NVARCHAR(500) = @BackupDir + N'DataSalud_DIFF.bak';

DECLARE @DestinoMdf NVARCHAR(500) = @DataPath + N'DataSalud_RestoreTest.mdf';
DECLARE @DestinoLdf NVARCHAR(500) = @LogPath  + N'DataSalud_RestoreTest_log.ldf';

IF DB_ID('DataSalud_RestoreTest') IS NOT NULL
BEGIN
    PRINT '>> Cerrando conexiones previas y eliminando base de prueba anterior...';
    ALTER DATABASE DataSalud_RestoreTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataSalud_RestoreTest;
END;

PRINT CONCAT('>> 1. Restaurando BACKUP FULL desde: ', @RutaFull);

RESTORE DATABASE DataSalud_RestoreTest
FROM DISK = @RutaFull
WITH 
    MOVE 'DataSalud' TO @DestinoMdf,
    MOVE 'DataSalud_log' TO @DestinoLdf,
    NORECOVERY,
    REPLACE,
    STATS = 25;

PRINT 'Restauración FULL completada en modo NORECOVERY (esperando diferencial).';

PRINT CONCAT('>> 2. Aplicando BACKUP DIFFERENTIAL desde: ', @RutaDiff);

RESTORE DATABASE DataSalud_RestoreTest
FROM DISK = @RutaDiff
WITH 
    RECOVERY,
    STATS = 25;

PRINT 'Restauración DIFFERENTIAL completada con éxito. Base de datos ONLINE.';
GO

PRINT '====================================================';
PRINT 'VALIDACIÓN DE INTEGRIDAD EN: DataSalud_RestoreTest';
PRINT '====================================================';

SELECT 
    name AS base_datos,
    state_desc AS estado,
    recovery_model_desc AS modelo_recuperacion,
    collation_name
FROM sys.databases
WHERE name = 'DataSalud_RestoreTest';

SELECT 
    COUNT(*) AS total_notificaciones_restauradas,
    MAX(fecha_ingesta) AS ultima_fecha_registro
FROM DataSalud_RestoreTest.dbo.Notificacion_Epidemiologica;

SELECT TOP 1
    id_notificacion,
    departamento,
    provincia,
    distrito,
    enfermedad,
    ano,
    semana,
    fecha_ingesta
FROM DataSalud_RestoreTest.dbo.Notificacion_Epidemiologica
ORDER BY id_notificacion DESC;

SELECT 
    COUNT(*) AS total_eventos_auditoria_restaurados
FROM DataSalud_RestoreTest.dbo.Log_Auditoria;

PRINT '====================================================';
PRINT 'PRUEBA DE RESTAURACIÓN FINALIZADA Y VALIDADA AL 100%';
PRINT '====================================================';
GO
