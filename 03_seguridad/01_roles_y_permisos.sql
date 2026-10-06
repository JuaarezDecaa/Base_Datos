USE DataSalud;
GO

PRINT '====================================================';
PRINT 'PASO 1: Creación de Roles de Base de Datos';
PRINT '====================================================';

IF DATABASE_PRINCIPAL_ID('rol_administrador') IS NULL
BEGIN
    CREATE ROLE rol_administrador;
    PRINT 'Rol rol_administrador creado exitosamente.';
END;

IF DATABASE_PRINCIPAL_ID('rol_analista') IS NULL
BEGIN
    CREATE ROLE rol_analista;
    PRINT 'Rol rol_analista creado exitosamente.';
END;

IF DATABASE_PRINCIPAL_ID('rol_auditor') IS NULL
BEGIN
    CREATE ROLE rol_auditor;
    PRINT 'Rol rol_auditor creado exitosamente.';
END;
GO

PRINT '====================================================';
PRINT 'PASO 2: Asignación de Privilegios Diferenciados';
PRINT '====================================================';

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Notificacion_Epidemiologica TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.stg_vigilancia_minsa TO rol_administrador;
GRANT SELECT, INSERT ON dbo.Log_Auditoria TO rol_administrador;
GRANT SELECT ON dbo.vw_stg_vigilancia_minsa TO rol_administrador;
GRANT EXECUTE ON dbo.sp_IngestarDesdeStaging TO rol_administrador;
GRANT EXECUTE ON dbo.sp_ValidarYRegistrarCaso TO rol_administrador;
GRANT EXECUTE ON dbo.fn_ClasificarCursoVida TO rol_administrador;
PRINT 'Privilegios asignados a: rol_administrador.';

GRANT SELECT ON dbo.Notificacion_Epidemiologica TO rol_analista;
GRANT SELECT ON dbo.vw_stg_vigilancia_minsa TO rol_analista;
GRANT EXECUTE ON dbo.fn_ClasificarCursoVida TO rol_analista;

DENY INSERT, UPDATE, DELETE ON dbo.Notificacion_Epidemiologica TO rol_analista;
DENY INSERT, UPDATE, DELETE ON dbo.stg_vigilancia_minsa TO rol_analista;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Log_Auditoria TO rol_analista;
DENY EXECUTE ON dbo.sp_IngestarDesdeStaging TO rol_analista;
DENY EXECUTE ON dbo.sp_ValidarYRegistrarCaso TO rol_analista;
PRINT 'Privilegios y restricciones asignados a: rol_analista.';

GRANT SELECT ON dbo.Log_Auditoria TO rol_auditor;
GRANT VIEW DEFINITION TO rol_auditor;

DENY INSERT, UPDATE, DELETE ON dbo.Log_Auditoria TO rol_auditor;
DENY INSERT, UPDATE, DELETE ON dbo.Notificacion_Epidemiologica TO rol_auditor;
DENY INSERT, UPDATE, DELETE ON dbo.stg_vigilancia_minsa TO rol_auditor;
DENY EXECUTE ON dbo.sp_IngestarDesdeStaging TO rol_auditor;
DENY EXECUTE ON dbo.sp_ValidarYRegistrarCaso TO rol_auditor;
PRINT 'Privilegios y restricciones asignados a: rol_auditor.';
GO

PRINT '====================================================';
PRINT 'PASO 3: Creación de Logins y Usuarios con Contraseñas';
PRINT '====================================================';

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_admin')
    CREATE LOGIN usr_admin WITH PASSWORD = 'AdminSalud2026!', CHECK_POLICY = OFF;

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_analista')
    CREATE LOGIN usr_analista WITH PASSWORD = 'AnalistaSalud2026!', CHECK_POLICY = OFF;

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_auditor')
    CREATE LOGIN usr_auditor WITH PASSWORD = 'AuditorSalud2026!', CHECK_POLICY = OFF;
GO

USE DataSalud;
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'usr_admin')
    CREATE USER usr_admin FOR LOGIN usr_admin;
ALTER ROLE rol_administrador ADD MEMBER usr_admin;

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'usr_analista')
    CREATE USER usr_analista FOR LOGIN usr_analista;
ALTER ROLE rol_analista ADD MEMBER usr_analista;

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'usr_auditor')
    CREATE USER usr_auditor FOR LOGIN usr_auditor;
ALTER ROLE rol_auditor ADD MEMBER usr_auditor;

PRINT 'Logins creados con contraseñas seguras y vinculados a sus roles.';
GO

PRINT '====================================================';
PRINT 'PASO 4: Pruebas de Seguridad y Validación de Permisos';
PRINT '====================================================';

EXECUTE AS USER = 'usr_analista';
PRINT '>> [Prueba Analista 1] Consulta de datos epidemiológicos:';
SELECT TOP 2 id_notificacion, enfermedad, edad, tipo_edad FROM dbo.Notificacion_Epidemiologica;
REVERT;

EXECUTE AS USER = 'usr_analista';
BEGIN TRY
    DELETE FROM dbo.Notificacion_Epidemiologica WHERE id_notificacion = 1;
    PRINT 'ERROR: No debió permitir borrar.';
END TRY
BEGIN CATCH
    PRINT CONCAT('>> [Prueba Analista 2 - Denegado Correcto]: ', ERROR_MESSAGE());
END CATCH;
REVERT;

EXECUTE AS USER = 'usr_analista';
BEGIN TRY
    SELECT * FROM dbo.Log_Auditoria;
    PRINT 'ERROR: No debió permitir ver la auditoría.';
END TRY
BEGIN CATCH
    PRINT CONCAT('>> [Prueba Analista 3 - Denegado Correcto]: ', ERROR_MESSAGE());
END CATCH;
REVERT;

EXECUTE AS USER = 'usr_auditor';
PRINT '>> [Prueba Auditor 1] Consulta de Log_Auditoria:';
SELECT TOP 2 id_log, nombre_tabla, operacion, usuario, fecha_evento FROM dbo.Log_Auditoria;
REVERT;

EXECUTE AS USER = 'usr_auditor';
BEGIN TRY
    DELETE FROM dbo.Log_Auditoria;
    PRINT 'ERROR: No debió permitir alterar la auditoría.';
END TRY
BEGIN CATCH
    PRINT CONCAT('>> [Prueba Auditor 2 - Denegado Correcto]: ', ERROR_MESSAGE());
END CATCH;
REVERT;

PRINT '====================================================';
PRINT 'CONTROL DE ACCESO Y SEGURIDAD VERIFICADOS CON ÉXITO';
PRINT '====================================================';
GO
