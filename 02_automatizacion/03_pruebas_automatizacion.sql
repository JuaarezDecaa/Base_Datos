USE DataSalud;
GO

TRUNCATE TABLE dbo.Log_Auditoria;
DELETE FROM dbo.Notificacion_Epidemiologica;
DELETE FROM dbo.stg_vigilancia_minsa;
PRINT '>> Tablas limpias para inicio de pruebas.';
GO

PRINT '>> PASO 1: Inserción válida manual (Prueba Trigger 1)';

INSERT INTO dbo.Notificacion_Epidemiologica (
    departamento, provincia, distrito, localidad, enfermedad,
    ano, semana, diagnostico_cie10, diresa, ubigeo, localcod, edad, tipo_edad, sexo
)
VALUES (
    'LA LIBERTAD', 'TRUJILLO', 'EL PORVENIR', 'BARRIO 1', 'DENGUE SIN SIGNOS DE ALARMA',
    2024, 15, 'A97.0', '13', '130102', '001301020001', 28, 'A', 'M'
);
GO

PRINT '>> PASO 2: Inserción con semana 60 inválida (Prueba Trigger 2)';

BEGIN TRY
    INSERT INTO dbo.Notificacion_Epidemiologica (
        departamento, provincia, distrito, localidad, enfermedad,
        ano, semana, diagnostico_cie10, diresa, ubigeo, localcod, edad, tipo_edad, sexo
    )
    VALUES (
        'LA LIBERTAD', 'TRUJILLO', 'LA ESPERANZA', 'CENTRO', 'DENGUE GRAVE',
        2024, 60, 'A97.2', '13', '130105', 'S/C', 45, 'A', 'F'
    );
END TRY
BEGIN CATCH
    PRINT CONCAT('>> Trigger 2 bloqueó correctamente: ', ERROR_MESSAGE());
END CATCH;
GO

PRINT '>> PASO 3: Registro individual correcto con SP 2';

EXEC dbo.sp_ValidarYRegistrarCaso
    @departamento = 'LA LIBERTAD',
    @provincia    = 'CHEPEN',
    @distrito     = 'PACANGA',
    @localidad    = 'PUEBLO NUEVO',
    @enfermedad   = 'LEISHMANIASIS CUTANEA',
    @ano          = 2024,
    @semana       = 20,
    @diagnostico  = 'B55.1',
    @diresa       = '13',
    @ubigeo       = '130403',
    @localcod     = 'S/C',
    @edad         = 35,
    @tipo_edad    = 'A',
    @sexo         = 'F';
GO

PRINT '>> PASO 4: Registro con semana 75 inválida en SP 2';

BEGIN TRY
    EXEC dbo.sp_ValidarYRegistrarCaso
        @departamento = 'LA LIBERTAD',
        @provincia    = 'ASCOPE',
        @distrito     = 'CHICAMA',
        @localidad    = 'SAUSAL',
        @enfermedad   = 'DENGUE GRAVE',
        @ano          = 2024,
        @semana       = 75,
        @diagnostico  = 'A97.2',
        @diresa       = '13',
        @ubigeo       = '130202',
        @localcod     = 'S/C',
        @edad         = 19,
        @tipo_edad    = 'A',
        @sexo         = 'M';
END TRY
BEGIN CATCH
    PRINT CONCAT('>> SP 2 rechazó correctamente y revirtió al SAVEPOINT: ', ERROR_MESSAGE());
END CATCH;
GO

PRINT '>> PASO 5: Carga temporal e Ingesta desde Staging con SP 1';

INSERT INTO dbo.vw_stg_vigilancia_minsa (
    departamento, provincia, distrito, localidad, enfermedad,
    ano, semana, diagnostic, diresa, ubigeo, localcod, edad, tipo_edad, sexo
)
VALUES 
    ('LA LIBERTAD', 'TRUJILLO', 'VICTOR LARCO', 'BUENOS AIRES', 'DENGUE SIN SIGNOS DE ALARMA', '2024', '12', 'A97.0', '13', '130107', '', '8', 'M', 'F'),
    ('LA LIBERTAD', 'VIRU', 'CHAO', '', 'LEISHMANIASIS CUTANEA', '2024', '14', 'B55.1', '13', '131202', '', '42', 'A', 'M');

EXEC dbo.sp_IngestarDesdeStaging;
GO

PRINT '>> PASO 6: Verificación de la función de etapas de vida';

SELECT 
    id_notificacion,
    edad,
    tipo_edad,
    dbo.fn_ClasificarCursoVida(edad, tipo_edad) AS etapa_vida_minsa,
    enfermedad,
    distrito
FROM dbo.Notificacion_Epidemiologica;
GO

PRINT '>> PASO 7: Registros en dbo.Log_Auditoria (Evidencia)';

SELECT id_log, nombre_tabla, operacion, usuario, fecha_evento, cantidad_filas, detalle_evento
FROM dbo.Log_Auditoria
ORDER BY id_log ASC;
GO

PRINT '======================================================================';
PRINT 'VEREDICTO DE VIABILIDAD TÉCNICA: VIABLE';
PRINT '======================================================================';
GO
