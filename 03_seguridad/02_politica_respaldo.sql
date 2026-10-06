USE master;
GO

PRINT '====================================================';
PRINT 'INICIANDO POLÍTICA DE RESPALDO PARA: DataSalud';
PRINT '====================================================';

DECLARE @BackupDir NVARCHAR(400);
SET @BackupDir = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(400));
IF RIGHT(@BackupDir, 1) <> '\' SET @BackupDir = @BackupDir + '\';

DECLARE @RutaFull NVARCHAR(500) = @BackupDir + N'DataSalud_FULL.bak';
DECLARE @RutaDiff NVARCHAR(500) = @BackupDir + N'DataSalud_DIFF.bak';

PRINT CONCAT('>> 1. Generando BACKUP FULL en: ', @RutaFull);

BACKUP DATABASE DataSalud
TO DISK = @RutaFull
WITH 
    FORMAT,
    INIT,
    NAME = 'DataSalud-Respaldo Completo Semanal',
    DESCRIPTION = 'Copia completa de seguridad de DataSalud para contingencias.',
    STATS = 25;

PRINT 'BACKUP FULL generado exitosamente.';
GO

USE DataSalud;
GO

PRINT '>> 2. Simulando nuevas notificaciones registradas durante el turno...';
INSERT INTO dbo.Notificacion_Epidemiologica (
    departamento, provincia, distrito, localidad, enfermedad,
    ano, semana, diagnostico_cie10, diresa, ubigeo, localcod, edad, tipo_edad, sexo
)
VALUES (
    'LA LIBERTAD', 'TRUJILLO', 'TRUJILLO', 'CENTRO HISTORICO', 'DENGUE SIN SIGNOS DE ALARMA',
    2024, 25, 'A97.0', '13', '130101', '001301010001', 31, 'A', 'F'
);
GO

USE master;
GO

DECLARE @BackupDir NVARCHAR(400);
SET @BackupDir = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(400));
IF RIGHT(@BackupDir, 1) <> '\' SET @BackupDir = @BackupDir + '\';
DECLARE @RutaDiff NVARCHAR(500) = @BackupDir + N'DataSalud_DIFF.bak';

PRINT CONCAT('>> 3. Generando BACKUP DIFFERENTIAL en: ', @RutaDiff);

BACKUP DATABASE DataSalud
TO DISK = @RutaDiff
WITH 
    DIFFERENTIAL,
    FORMAT,
    INIT,
    NAME = 'DataSalud-Respaldo Diferencial Diario',
    DESCRIPTION = 'Copia diferencial que resguarda los registros ingresados hoy.',
    STATS = 25;

PRINT 'BACKUP DIFFERENTIAL generado exitosamente.';
GO

PRINT '====================================================';
PRINT 'EVIDENCIA DE RESPALDOS GENERADOS (msdb.dbo.backupset):';
PRINT '====================================================';

SELECT 
    b.database_name,
    CASE b.type 
        WHEN 'D' THEN 'COMPLETO (FULL)'
        WHEN 'I' THEN 'DIFERENCIAL (DIFF)'
        WHEN 'L' THEN 'LOG DE TRANSACCIONES'
        ELSE b.type 
    END AS tipo_respaldo,
    b.name AS nombre_respaldo,
    b.backup_start_date AS fecha_inicio,
    b.backup_finish_date AS fecha_fin,
    CAST(b.backup_size / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS tamano_mb,
    f.physical_device_name AS ruta_archivo
FROM msdb.dbo.backupset b
JOIN msdb.dbo.backupmediafamily f ON b.media_set_id = f.media_set_id
WHERE b.database_name = 'DataSalud'
ORDER BY b.backup_finish_date DESC;
GO
