USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DataSalud_DW')
BEGIN
    CREATE DATABASE DataSalud_DW;
END;
GO

USE DataSalud_DW;
GO

IF OBJECT_ID('dbo.Fact_Vigilancia_Epidemiologica', 'U') IS NOT NULL
    DROP TABLE dbo.Fact_Vigilancia_Epidemiologica;
GO

IF OBJECT_ID('dbo.Dim_Tiempo', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Tiempo;
GO

IF OBJECT_ID('dbo.Dim_Ubicacion', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Ubicacion;
GO

IF OBJECT_ID('dbo.Dim_Enfermedad', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Enfermedad;
GO

IF OBJECT_ID('dbo.Dim_Paciente', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Paciente;
GO

IF OBJECT_ID('dbo.Dim_Establecimiento', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Establecimiento;
GO

CREATE TABLE dbo.Dim_Tiempo (
    id_tiempo                INT PRIMARY KEY,
    ano                      SMALLINT NOT NULL,
    semana_epidemiologica    TINYINT NOT NULL,
    mes                      TINYINT NOT NULL,
    nombre_mes               VARCHAR(20) NOT NULL,
    trimestre                TINYINT NOT NULL,
    semestre                 TINYINT NOT NULL,
    periodo_anual            VARCHAR(10) NOT NULL
);
GO

CREATE TABLE dbo.Dim_Ubicacion (
    id_ubicacion             INT PRIMARY KEY,
    ubigeo                   CHAR(6) NOT NULL,
    departamento             VARCHAR(50) NOT NULL,
    provincia                VARCHAR(50) NOT NULL,
    distrito                 VARCHAR(50) NOT NULL,
    diresa                   VARCHAR(10) NOT NULL
);
GO

CREATE TABLE dbo.Dim_Enfermedad (
    id_enfermedad            INT PRIMARY KEY,
    diagnostico_cie10        VARCHAR(10) NOT NULL,
    nombre_enfermedad        VARCHAR(100) NOT NULL,
    tipo_patologia           VARCHAR(50) NOT NULL,
    es_metaxenica            BIT NOT NULL
);
GO

CREATE TABLE dbo.Dim_Paciente (
    id_paciente              INT PRIMARY KEY,
    edad                     SMALLINT NOT NULL,
    tipo_edad                CHAR(1) NOT NULL,
    sexo                     CHAR(1) NOT NULL,
    curso_vida_minsa         VARCHAR(20) NOT NULL
);
GO

CREATE TABLE dbo.Dim_Establecimiento (
    id_establecimiento       INT PRIMARY KEY,
    localcod                 VARCHAR(20) NOT NULL,
    nombre_establecimiento   VARCHAR(150) NOT NULL,
    tiene_codigo_oficial     BIT NOT NULL
);
GO

CREATE TABLE dbo.Fact_Vigilancia_Epidemiologica (
    id_hecho                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_tiempo                INT NOT NULL,
    id_ubicacion             INT NOT NULL,
    id_enfermedad            INT NOT NULL,
    id_paciente              INT NOT NULL,
    id_establecimiento       INT NOT NULL,
    cantidad_casos           INT NOT NULL DEFAULT 1,
    edad_paciente            SMALLINT NOT NULL,
    es_caso_confirmado       BIT NOT NULL DEFAULT 1,
    es_caso_grave            BIT NOT NULL DEFAULT 0,
    fecha_carga              DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Fact_Tiempo FOREIGN KEY (id_tiempo) 
        REFERENCES dbo.Dim_Tiempo(id_tiempo),
    CONSTRAINT FK_Fact_Ubicacion FOREIGN KEY (id_ubicacion) 
        REFERENCES dbo.Dim_Ubicacion(id_ubicacion),
    CONSTRAINT FK_Fact_Enfermedad FOREIGN KEY (id_enfermedad) 
        REFERENCES dbo.Dim_Enfermedad(id_enfermedad),
    CONSTRAINT FK_Fact_Paciente FOREIGN KEY (id_paciente) 
        REFERENCES dbo.Dim_Paciente(id_paciente),
    CONSTRAINT FK_Fact_Establecimiento FOREIGN KEY (id_establecimiento) 
        REFERENCES dbo.Dim_Establecimiento(id_establecimiento)
);
GO

CREATE NONCLUSTERED INDEX IX_Fact_Tiempo ON dbo.Fact_Vigilancia_Epidemiologica(id_tiempo);
CREATE NONCLUSTERED INDEX IX_Fact_Ubicacion ON dbo.Fact_Vigilancia_Epidemiologica(id_ubicacion);
CREATE NONCLUSTERED INDEX IX_Fact_Enfermedad ON dbo.Fact_Vigilancia_Epidemiologica(id_enfermedad);
CREATE NONCLUSTERED INDEX IX_Fact_Paciente ON dbo.Fact_Vigilancia_Epidemiologica(id_paciente);
CREATE NONCLUSTERED INDEX IX_Fact_Establecimiento ON dbo.Fact_Vigilancia_Epidemiologica(id_establecimiento);
GO

IF OBJECT_ID('dbo.Staging_Vigilancia_LaLibertad', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Vigilancia_LaLibertad;
GO

CREATE TABLE dbo.Staging_Vigilancia_LaLibertad (
    id_caso INT,
    ano VARCHAR(10),
    semana VARCHAR(10),
    departamento VARCHAR(100),
    provincia VARCHAR(100),
    distrito VARCHAR(100),
    diresa VARCHAR(50),
    ubigeo VARCHAR(10),
    enfermedad VARCHAR(100),
    diagnostic VARCHAR(20),
    edad VARCHAR(20),
    tipo_edad VARCHAR(5),
    sexo VARCHAR(5),
    localcod VARCHAR(50)
);
GO

PRINT '>> [01_ddl_datawarehouse.sql] Modelo dimensional Kimball (DataSalud_DW) creado exitosamente.';
GO
