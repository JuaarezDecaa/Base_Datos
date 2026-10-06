USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DataSalud')
BEGIN
    CREATE DATABASE DataSalud;
END;
GO

USE DataSalud;
GO

IF OBJECT_ID('dbo.Log_Auditoria', 'U') IS NOT NULL 
    DROP TABLE dbo.Log_Auditoria;
GO

CREATE TABLE dbo.Log_Auditoria (
    id_log         INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tabla   VARCHAR(100) NOT NULL,
    operacion      VARCHAR(30) NOT NULL,
    usuario        VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    fecha_evento   DATETIME NOT NULL DEFAULT GETDATE(),
    cantidad_filas INT NULL,
    detalle_evento NVARCHAR(MAX) NULL
);
GO

IF OBJECT_ID('dbo.vw_stg_vigilancia_minsa', 'V') IS NOT NULL
    DROP VIEW dbo.vw_stg_vigilancia_minsa;
GO

IF OBJECT_ID('dbo.stg_vigilancia_minsa', 'U') IS NOT NULL 
    DROP TABLE dbo.stg_vigilancia_minsa;
GO

CREATE TABLE dbo.stg_vigilancia_minsa (
    id_caso      INT IDENTITY(1,1) PRIMARY KEY,
    departamento VARCHAR(100) NULL,
    provincia    VARCHAR(100) NULL,
    distrito     VARCHAR(100) NULL,
    localidad    VARCHAR(150) NULL,
    enfermedad   VARCHAR(100) NULL,
    ano          VARCHAR(10)  NULL,
    semana       VARCHAR(10)  NULL,
    diagnostic   VARCHAR(20)  NULL,
    diresa       VARCHAR(50)  NULL,
    ubigeo       VARCHAR(10)  NULL,
    localcod     VARCHAR(50)  NULL,
    edad         VARCHAR(20)  NULL,
    tipo_edad    VARCHAR(5)   NULL,
    sexo         VARCHAR(5)   NULL
);
GO

CREATE VIEW dbo.vw_stg_vigilancia_minsa AS
SELECT 
    departamento, provincia, distrito, localidad, enfermedad,
    ano, semana, diagnostic, diresa, ubigeo, localcod, edad, tipo_edad, sexo
FROM dbo.stg_vigilancia_minsa;
GO

IF OBJECT_ID('dbo.Notificacion_Epidemiologica', 'U') IS NOT NULL 
    DROP TABLE dbo.Notificacion_Epidemiologica;
GO

CREATE TABLE dbo.Notificacion_Epidemiologica (
    id_notificacion   INT IDENTITY(1,1) PRIMARY KEY,
    departamento      VARCHAR(50) NOT NULL,
    provincia         VARCHAR(50) NOT NULL,
    distrito          VARCHAR(50) NOT NULL,
    localidad         VARCHAR(100) NOT NULL DEFAULT 'SIN INFORMACION',
    enfermedad        VARCHAR(100) NOT NULL,
    ano               SMALLINT NOT NULL,
    semana            TINYINT NOT NULL,
    diagnostico_cie10 VARCHAR(10) NOT NULL,
    diresa            VARCHAR(10) NOT NULL DEFAULT 'S/D',
    ubigeo            CHAR(6) NOT NULL,
    localcod          VARCHAR(20) NOT NULL DEFAULT 'S/C',
    edad              SMALLINT NOT NULL,
    tipo_edad         CHAR(1) NOT NULL,
    sexo              CHAR(1) NOT NULL,
    fecha_ingesta     DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_registro  VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER
);
GO

PRINT '>> Base de datos y tablas creadas exitosamente.';
GO