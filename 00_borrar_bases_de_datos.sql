USE master;
GO

IF DB_ID('DataSalud') IS NOT NULL
BEGIN
    ALTER DATABASE DataSalud SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataSalud;
    PRINT '>> Base de datos DataSalud eliminada.';
END;
GO

IF DB_ID('DataSalud_RestoreTest') IS NOT NULL
BEGIN
    ALTER DATABASE DataSalud_RestoreTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataSalud_RestoreTest;
    PRINT '>> Base de datos DataSalud_RestoreTest eliminada.';
END;
GO

IF DB_ID('DataSalud_DW') IS NOT NULL
BEGIN
    ALTER DATABASE DataSalud_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataSalud_DW;
    PRINT '>> Base de datos DataSalud_DW eliminada.';
END;
GO

IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_admin')
BEGIN
    DROP LOGIN usr_admin;
    PRINT '>> Login usr_admin eliminado.';
END;
GO

IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_analista')
BEGIN
    DROP LOGIN usr_analista;
    PRINT '>> Login usr_analista eliminado.';
END;
GO

IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'usr_auditor')
BEGIN
    DROP LOGIN usr_auditor;
    PRINT '>> Login usr_auditor eliminado.';
END;
GO

PRINT '==================================================';
PRINT 'ENTORNO REINICIADO EXITOSAMENTE';
PRINT '==================================================';
GO
