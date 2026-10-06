USE DataSalud_DW;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_LimpiarDW
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Fact_Vigilancia_Epidemiologica;
    DELETE FROM dbo.Dim_Establecimiento;
    DELETE FROM dbo.Dim_Paciente;
    DELETE FROM dbo.Dim_Enfermedad;
    DELETE FROM dbo.Dim_Ubicacion;
    DELETE FROM dbo.Dim_Tiempo;
    IF OBJECT_ID('dbo.Staging_Vigilancia_LaLibertad', 'U') IS NOT NULL
        TRUNCATE TABLE dbo.Staging_Vigilancia_LaLibertad;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Dim_Tiempo
AS
BEGIN
    SET NOCOUNT ON;
    WITH Semanas AS (
        SELECT 1 AS sem
        UNION ALL
        SELECT sem + 1 FROM Semanas WHERE sem < 53
    ),
    Anios AS (
        SELECT 2000 AS anio
        UNION ALL
        SELECT anio + 1 FROM Anios WHERE anio < 2025
    )
    INSERT INTO dbo.Dim_Tiempo (id_tiempo, ano, semana_epidemiologica, mes, nombre_mes, trimestre, semestre, periodo_anual)
    SELECT 
        (a.anio * 100 + s.sem) AS id_tiempo,
        CAST(a.anio AS SMALLINT) AS ano,
        CAST(s.sem AS TINYINT) AS semana_epidemiologica,
        CAST(CASE 
            WHEN s.sem BETWEEN 1 AND 4 THEN 1
            WHEN s.sem BETWEEN 5 AND 8 THEN 2
            WHEN s.sem BETWEEN 9 AND 13 THEN 3
            WHEN s.sem BETWEEN 14 AND 17 THEN 4
            WHEN s.sem BETWEEN 18 AND 22 THEN 5
            WHEN s.sem BETWEEN 23 AND 26 THEN 6
            WHEN s.sem BETWEEN 27 AND 30 THEN 7
            WHEN s.sem BETWEEN 31 AND 35 THEN 8
            WHEN s.sem BETWEEN 36 AND 39 THEN 9
            WHEN s.sem BETWEEN 40 AND 43 THEN 10
            WHEN s.sem BETWEEN 44 AND 48 THEN 11
            ELSE 12
        END AS TINYINT) AS mes,
        CASE 
            WHEN s.sem BETWEEN 1 AND 4 THEN 'Enero'
            WHEN s.sem BETWEEN 5 AND 8 THEN 'Febrero'
            WHEN s.sem BETWEEN 9 AND 13 THEN 'Marzo'
            WHEN s.sem BETWEEN 14 AND 17 THEN 'Abril'
            WHEN s.sem BETWEEN 18 AND 22 THEN 'Mayo'
            WHEN s.sem BETWEEN 23 AND 26 THEN 'Junio'
            WHEN s.sem BETWEEN 27 AND 30 THEN 'Julio'
            WHEN s.sem BETWEEN 31 AND 35 THEN 'Agosto'
            WHEN s.sem BETWEEN 36 AND 39 THEN 'Setiembre'
            WHEN s.sem BETWEEN 40 AND 43 THEN 'Octubre'
            WHEN s.sem BETWEEN 44 AND 48 THEN 'Noviembre'
            ELSE 'Diciembre'
        END AS nombre_mes,
        CAST(CASE 
            WHEN s.sem BETWEEN 1 AND 13 THEN 1
            WHEN s.sem BETWEEN 14 AND 26 THEN 2
            WHEN s.sem BETWEEN 27 AND 39 THEN 3
            ELSE 4
        END AS TINYINT) AS trimestre,
        CAST(CASE WHEN s.sem <= 26 THEN 1 ELSE 2 END AS TINYINT) AS semestre,
        CAST(a.anio AS VARCHAR(10)) AS periodo_anual
    FROM Anios a
    CROSS JOIN Semanas s
    OPTION (MAXRECURSION 100);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Dim_Ubicacion
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Ubicacion (id_ubicacion, ubigeo, departamento, provincia, distrito, diresa)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ubigeo) AS id_ubicacion,
        ubigeo,
        departamento,
        provincia,
        distrito,
        diresa
    FROM (
        SELECT DISTINCT 
            CAST(RTRIM(LTRIM(REPLACE(ubigeo, '"', ''))) AS CHAR(6)) AS ubigeo,
            CAST(RTRIM(LTRIM(REPLACE(departamento, '"', ''))) AS VARCHAR(50)) AS departamento,
            CAST(RTRIM(LTRIM(REPLACE(provincia, '"', ''))) AS VARCHAR(50)) AS provincia,
            CAST(RTRIM(LTRIM(REPLACE(distrito, '"', ''))) AS VARCHAR(50)) AS distrito,
            CAST(RTRIM(LTRIM(REPLACE(diresa, '"', ''))) AS VARCHAR(10)) AS diresa
        FROM DataSalud.dbo.stg_vigilancia_minsa
        WHERE departamento LIKE '%LIBERTAD%'
          AND ubigeo IS NOT NULL AND LEN(RTRIM(LTRIM(REPLACE(ubigeo, '"', '')))) = 6
    ) t;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Dim_Enfermedad
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Enfermedad (id_enfermedad, diagnostico_cie10, nombre_enfermedad, tipo_patologia, es_metaxenica)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY diagnostico_cie10) AS id_enfermedad,
        diagnostico_cie10,
        nombre_enfermedad,
        CASE 
            WHEN nombre_enfermedad LIKE '%DENGUE%' THEN 'Dengue Arbovirus'
            ELSE 'Leishmaniasis Parasitaria'
        END AS tipo_patologia,
        1 AS es_metaxenica
    FROM (
        SELECT DISTINCT 
            CAST(RTRIM(LTRIM(REPLACE(diagnostic, '"', ''))) AS VARCHAR(10)) AS diagnostico_cie10,
            CAST(UPPER(RTRIM(LTRIM(REPLACE(enfermedad, '"', '')))) AS VARCHAR(100)) AS nombre_enfermedad
        FROM DataSalud.dbo.stg_vigilancia_minsa
        WHERE departamento LIKE '%LIBERTAD%'
          AND diagnostic IS NOT NULL AND RTRIM(LTRIM(REPLACE(diagnostic, '"', ''))) <> ''
    ) t;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Dim_Paciente
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Paciente (id_paciente, edad, tipo_edad, sexo, curso_vida_minsa)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY edad, tipo_edad, sexo) AS id_paciente,
        edad,
        tipo_edad,
        sexo,
        DataSalud.dbo.fn_ClasificarCursoVida(edad, tipo_edad) AS curso_vida_minsa
    FROM (
        SELECT DISTINCT 
            CAST(CASE 
                WHEN TRY_CAST(RTRIM(LTRIM(REPLACE(edad, '"', ''))) AS INT) BETWEEN 0 AND 120 
                    THEN TRY_CAST(RTRIM(LTRIM(REPLACE(edad, '"', ''))) AS SMALLINT)
                ELSE 999 
            END AS SMALLINT) AS edad,
            CAST(UPPER(LEFT(RTRIM(LTRIM(REPLACE(ISNULL(tipo_edad, 'A'), '"', ''))), 1)) AS CHAR(1)) AS tipo_edad,
            CAST(UPPER(LEFT(RTRIM(LTRIM(REPLACE(ISNULL(sexo, 'M'), '"', ''))), 1)) AS CHAR(1)) AS sexo
        FROM DataSalud.dbo.stg_vigilancia_minsa
        WHERE departamento LIKE '%LIBERTAD%'
    ) t;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Dim_Establecimiento
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Dim_Establecimiento (id_establecimiento, localcod, nombre_establecimiento, tiene_codigo_oficial)
    SELECT 
        ROW_NUMBER() OVER (ORDER BY localcod) AS id_establecimiento,
        localcod,
        CASE 
            WHEN localcod = 'S/C' THEN 'ESTABLECIMIENTO NO ESPECIFICADO (S/C)'
            ELSE 'ESTABLECIMIENTO REGISTRADO'
        END AS nombre_establecimiento,
        CASE WHEN localcod = 'S/C' THEN 0 ELSE 1 END AS tiene_codigo_oficial
    FROM (
        SELECT DISTINCT 
            CAST(CASE 
                WHEN localcod IS NULL OR RTRIM(LTRIM(REPLACE(localcod, '"', ''))) IN ('', '0', 'nan') 
                    THEN 'S/C'
                ELSE RTRIM(LTRIM(REPLACE(localcod, '"', '')))
            END AS VARCHAR(20)) AS localcod
        FROM DataSalud.dbo.stg_vigilancia_minsa
        WHERE departamento LIKE '%LIBERTAD%'
    ) t;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ETL_Cargar_Fact_Vigilancia
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Staging_Vigilancia_LaLibertad)
    BEGIN
        INSERT INTO dbo.Staging_Vigilancia_LaLibertad (
            departamento, provincia, distrito, diresa, ubigeo,
            enfermedad, diagnostic, ano, semana, edad, tipo_edad, sexo, localcod
        )
        SELECT 
            departamento, provincia, distrito, diresa, ubigeo,
            enfermedad, diagnostic, ano, semana, edad, tipo_edad, sexo, localcod
        FROM DataSalud.dbo.stg_vigilancia_minsa
        WHERE departamento LIKE '%LIBERTAD%';
    END;

    INSERT INTO dbo.Fact_Vigilancia_Epidemiologica (
        id_tiempo, id_ubicacion, id_enfermedad, id_paciente, id_establecimiento,
        cantidad_casos, edad_paciente, es_caso_confirmado, es_caso_grave
    )
    SELECT TOP (5000)
        t.id_tiempo,
        u.id_ubicacion,
        e.id_enfermedad,
        p.id_paciente,
        est.id_establecimiento,
        1 AS cantidad_casos,
        p.edad AS edad_paciente,
        1 AS es_caso_confirmado,
        CASE WHEN e.nombre_enfermedad LIKE '%GRAVE%' THEN 1 ELSE 0 END AS es_caso_grave
    FROM (
        SELECT 
            TRY_CAST(RTRIM(LTRIM(REPLACE(ano, '"', ''))) AS SMALLINT) AS ano,
            TRY_CAST(RTRIM(LTRIM(REPLACE(semana, '"', ''))) AS TINYINT) AS semana,
            CAST(RTRIM(LTRIM(REPLACE(ubigeo, '"', ''))) AS CHAR(6)) AS ubigeo,
            CAST(RTRIM(LTRIM(REPLACE(diagnostic, '"', ''))) AS VARCHAR(10)) AS diagnostic,
            CAST(CASE 
                WHEN TRY_CAST(RTRIM(LTRIM(REPLACE(edad, '"', ''))) AS INT) BETWEEN 0 AND 120 
                    THEN TRY_CAST(RTRIM(LTRIM(REPLACE(edad, '"', ''))) AS SMALLINT)
                ELSE 999 
            END AS SMALLINT) AS edad_limpia,
            CAST(UPPER(LEFT(RTRIM(LTRIM(REPLACE(ISNULL(tipo_edad, 'A'), '"', ''))), 1)) AS CHAR(1)) AS tipo_edad,
            CAST(UPPER(LEFT(RTRIM(LTRIM(REPLACE(ISNULL(sexo, 'M'), '"', ''))), 1)) AS CHAR(1)) AS sexo,
            CAST(CASE 
                WHEN localcod IS NULL OR RTRIM(LTRIM(REPLACE(localcod, '"', ''))) IN ('', '0', 'nan') 
                    THEN 'S/C'
                ELSE RTRIM(LTRIM(REPLACE(localcod, '"', '')))
            END AS VARCHAR(20)) AS localcod
        FROM dbo.Staging_Vigilancia_LaLibertad
        WHERE TRY_CAST(RTRIM(LTRIM(REPLACE(semana, '"', ''))) AS INT) BETWEEN 1 AND 53
    ) src
    JOIN dbo.Dim_Tiempo t 
        ON t.ano = src.ano AND t.semana_epidemiologica = src.semana
    JOIN dbo.Dim_Ubicacion u 
        ON u.ubigeo = src.ubigeo
    JOIN dbo.Dim_Enfermedad e 
        ON e.diagnostico_cie10 = src.diagnostic
    JOIN dbo.Dim_Paciente p 
        ON p.edad = src.edad_limpia AND p.tipo_edad = src.tipo_edad AND p.sexo = src.sexo
    JOIN dbo.Dim_Establecimiento est 
        ON est.localcod = src.localcod;
END;
GO
