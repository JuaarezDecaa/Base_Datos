USE DataSalud;
GO

IF OBJECT_ID('dbo.fn_ClasificarCursoVida', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_ClasificarCursoVida;
GO

CREATE FUNCTION dbo.fn_ClasificarCursoVida (
    @edad INT,
    @tipo_edad CHAR(1)
)
RETURNS VARCHAR(20)
AS
BEGIN
    IF @tipo_edad IN ('M', 'D') 
        RETURN 'NIÑO';

    IF @edad IS NULL OR @edad < 0 OR @edad > 120 
        RETURN 'DESCONOCIDO';

    IF @edad <= 11 RETURN 'NIÑO';
    IF @edad <= 17 RETURN 'ADOLESCENTE';
    IF @edad <= 29 RETURN 'JOVEN';
    IF @edad <= 59 RETURN 'ADULTO';

    RETURN 'ADULTO MAYOR';
END;
GO

IF OBJECT_ID('dbo.trg_Auditoria_Insert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Auditoria_Insert;
GO

CREATE TRIGGER dbo.trg_Auditoria_Insert
ON dbo.Notificacion_Epidemiologica
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total INT = (SELECT COUNT(*) FROM inserted);

    IF @total > 0
    BEGIN
        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'Notificacion_Epidemiologica',
            'INSERT',
            SYSTEM_USER,
            GETDATE(),
            @total,
            CONCAT('Auditoría automática: Se insertaron ', @total, ' caso(s) en la base de datos.')
        );
    END;
END;
GO

IF OBJECT_ID('dbo.trg_Integridad_Semana', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Integridad_Semana;
GO

CREATE TRIGGER dbo.trg_Integridad_Semana
ON dbo.Notificacion_Epidemiologica
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE semana < 1 OR semana > 53 OR edad < 0)
    BEGIN
        ROLLBACK TRANSACTION;

        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'Notificacion_Epidemiologica',
            'RECHAZO_INTEGRIDAD',
            SYSTEM_USER,
            GETDATE(),
            1,
            'Alerta de Integridad: Se bloqueó una inserción con semana fuera de rango (1-53) o edad negativa.'
        );

        THROW 51000, 'Error de Integridad: La semana debe estar entre 1 y 53, y la edad no puede ser negativa.', 1;
    END;
END;
GO

IF OBJECT_ID('dbo.sp_IngestarDesdeStaging', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_IngestarDesdeStaging;
GO

CREATE PROCEDURE dbo.sp_IngestarDesdeStaging
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SAVE TRANSACTION PuntoStaging;

        INSERT INTO dbo.Notificacion_Epidemiologica (
            departamento, provincia, distrito, localidad, enfermedad,
            ano, semana, diagnostico_cie10, diresa, ubigeo, localcod, edad, tipo_edad, sexo
        )
        SELECT DISTINCT
            REPLACE(departamento, '"', ''),
            REPLACE(provincia, '"', ''),
            REPLACE(distrito, '"', ''),
            ISNULL(NULLIF(REPLACE(localidad, '"', ''), ''), 'SIN INFORMACION'),
            REPLACE(enfermedad, '"', ''),
            CAST(REPLACE(ano, '"', '') AS SMALLINT),
            CAST(REPLACE(semana, '"', '') AS TINYINT),
            REPLACE(diagnostic, '"', ''),
            ISNULL(NULLIF(REPLACE(diresa, '"', ''), ''), 'S/D'),
            REPLACE(ubigeo, '"', ''),
            ISNULL(NULLIF(REPLACE(localcod, '"', ''), ''), 'S/C'),
            CASE 
                WHEN TRY_CAST(REPLACE(edad, '"', '') AS INT) > 120 THEN 999 
                ELSE CAST(REPLACE(edad, '"', '') AS SMALLINT) 
            END,
            CAST(LEFT(REPLACE(tipo_edad, '"', ''), 1) AS CHAR(1)),
            CAST(LEFT(REPLACE(sexo, '"', ''), 1) AS CHAR(1))
        FROM dbo.stg_vigilancia_minsa
        WHERE TRY_CAST(REPLACE(semana, '"', '') AS INT) BETWEEN 1 AND 53;

        DECLARE @filas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'stg_vigilancia_minsa',
            'INGESTA_STAGING',
            SYSTEM_USER,
            GETDATE(),
            @filas,
            CONCAT('Ingesta masiva finalizada exitosamente. Filas migradas a Notificacion_Epidemiologica: ', @filas)
        );

        PRINT CONCAT('>> Ingesta completada con éxito. Filas procesadas: ', @filas);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION PuntoStaging;
            COMMIT TRANSACTION;
        END;

        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'stg_vigilancia_minsa',
            'ERROR_INGESTA',
            SYSTEM_USER,
            GETDATE(),
            0,
            CONCAT('Fallo en ingesta: ', ERROR_MESSAGE())
        );

        THROW;
    END CATCH;
END;
GO

IF OBJECT_ID('dbo.sp_ValidarYRegistrarCaso', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ValidarYRegistrarCaso;
GO

CREATE PROCEDURE dbo.sp_ValidarYRegistrarCaso
    @departamento VARCHAR(50),
    @provincia    VARCHAR(50),
    @distrito     VARCHAR(50),
    @localidad    VARCHAR(100) = 'SIN INFORMACION',
    @enfermedad   VARCHAR(100),
    @ano          SMALLINT,
    @semana       TINYINT,
    @diagnostico  VARCHAR(10),
    @diresa       VARCHAR(10),
    @ubigeo       CHAR(6),
    @localcod     VARCHAR(20)  = 'S/C',
    @edad         SMALLINT,
    @tipo_edad    CHAR(1)      = 'A',
    @sexo         CHAR(1)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SAVE TRANSACTION PuntoValidacion;

        IF @semana < 1 OR @semana > 53
            THROW 50001, 'Validación rechazada: La semana epidemiológica debe estar comprendida entre 1 y 53.', 1;

        IF @edad < 0
            THROW 50002, 'Validación rechazada: La edad del paciente no puede ser un número negativo.', 1;

        INSERT INTO dbo.Notificacion_Epidemiologica (
            departamento, provincia, distrito, localidad, enfermedad,
            ano, semana, diagnostico_cie10, diresa, ubigeo, localcod, edad, tipo_edad, sexo
        )
        VALUES (
            @departamento, @provincia, @distrito, @localidad, @enfermedad,
            @ano, @semana, @diagnostico, @diresa, @ubigeo, @localcod, @edad, @tipo_edad, @sexo
        );

        COMMIT TRANSACTION;

        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'Notificacion_Epidemiologica',
            'INSERT_INDIVIDUAL',
            SYSTEM_USER,
            GETDATE(),
            1,
            CONCAT('Registro individual exitoso: Caso de ', @enfermedad, ' en ', @distrito, ' guardado.')
        );

        PRINT '>> Caso registrado exitosamente vía procedimiento almacenado.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION PuntoValidacion;
            COMMIT TRANSACTION;
        END;

        INSERT INTO dbo.Log_Auditoria (nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento)
        VALUES (
            'Notificacion_Epidemiologica',
            'RECHAZO_SP',
            SYSTEM_USER,
            GETDATE(),
            0,
            CONCAT('Rechazo en SP sp_ValidarYRegistrarCaso: ', ERROR_MESSAGE())
        );

        THROW;
    END CATCH;
END;
GO

PRINT '>> Todos los objetos de automatización creados exitosamente.';
GO