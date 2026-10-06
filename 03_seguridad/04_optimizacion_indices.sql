USE DataSalud;
GO

PRINT '============================================================';
PRINT 'OPTIMIZACIÓN DE CONSULTA CRÍTICA EN DataSalud';
PRINT '============================================================';

IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Notificacion_Enfermedad_Ano_Semana' AND object_id = OBJECT_ID('dbo.Notificacion_Epidemiologica'))
BEGIN
    DROP INDEX IX_Notificacion_Enfermedad_Ano_Semana ON dbo.Notificacion_Epidemiologica;
    PRINT '>> Índice previo eliminado para medir la línea base sin indexación.';
END;
GO

PRINT '';
PRINT '============================================================';
PRINT 'PRUEBA 1: EJECUTANDO CONSULTA SIN ÍNDICE (LÍNEA BASE)';
PRINT '============================================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    departamento,
    provincia,
    distrito,
    enfermedad,
    ano,
    COUNT(*) AS total_casos,
    AVG(edad) AS edad_promedio
FROM dbo.Notificacion_Epidemiologica
WHERE enfermedad = 'DENGUE SIN SIGNOS DE ALARMA'
  AND ano = 2024
  AND semana BETWEEN 10 AND 20
GROUP BY departamento, provincia, distrito, enfermedad, ano
ORDER BY total_casos DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT '';
PRINT '============================================================';
PRINT 'CREANDO ÍNDICE NO AGRUPADO: IX_Notificacion_Enfermedad_Ano_Semana';
PRINT '============================================================';

CREATE NONCLUSTERED INDEX IX_Notificacion_Enfermedad_Ano_Semana
ON dbo.Notificacion_Epidemiologica (enfermedad, ano, semana)
INCLUDE (departamento, provincia, distrito, edad);

PRINT 'Índice creado exitosamente.';
GO

PRINT '';
PRINT '============================================================';
PRINT 'PRUEBA 2: EJECUTANDO CONSULTA CON ÍNDICE IMPLEMENTADO';
PRINT '============================================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    departamento,
    provincia,
    distrito,
    enfermedad,
    ano,
    COUNT(*) AS total_casos,
    AVG(edad) AS edad_promedio
FROM dbo.Notificacion_Epidemiologica
WHERE enfermedad = 'DENGUE SIN SIGNOS DE ALARMA'
  AND ano = 2024
  AND semana BETWEEN 10 AND 20
GROUP BY departamento, provincia, distrito, enfermedad, ano
ORDER BY total_casos DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT '';
PRINT '============================================================';
PRINT 'ESTADO DEL ÍNDICE CREADO (sys.indexes / dm_db_index_physical_stats):';
PRINT '============================================================';

SELECT 
    i.name AS nombre_indice,
    i.type_desc AS tipo_indice,
    s.page_count AS total_paginas,
    CAST(s.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS porcentaje_fragmentacion
FROM sys.indexes i
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), i.object_id, i.index_id, NULL, 'LIMITED') s
WHERE i.object_id = OBJECT_ID('dbo.Notificacion_Epidemiologica')
  AND i.name = 'IX_Notificacion_Enfermedad_Ano_Semana';
GO

PRINT '============================================================';
PRINT 'OPTIMIZACIÓN Y ANÁLISIS DE RENDIMIENTO COMPLETADOS CON ÉXITO';
PRINT '============================================================';
GO
