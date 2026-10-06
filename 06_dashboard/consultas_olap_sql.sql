USE DataSalud_DW;
GO

SELECT 
    ISNULL(u.departamento, 'TOTAL REGION') AS departamento,
    ISNULL(u.provincia, 'TOTAL PROVINCIA') AS provincia,
    ISNULL(u.distrito, 'TOTAL DISTRITO') AS distrito,
    SUM(f.cantidad_casos) AS total_casos,
    SUM(CAST(f.es_caso_grave AS INT)) AS total_casos_graves
FROM dbo.Fact_Vigilancia_Epidemiologica f
JOIN dbo.Dim_Ubicacion u ON f.id_ubicacion = u.id_ubicacion
GROUP BY ROLLUP (u.departamento, u.provincia, u.distrito);
GO

SELECT 
    ISNULL(e.nombre_enfermedad, 'TODAS LAS ENFERMEDADES') AS enfermedad,
    ISNULL(p.curso_vida_minsa, 'TODOS LOS CURSOS DE VIDA') AS curso_vida,
    ISNULL(CAST(t.ano AS VARCHAR(10)), 'TODOS LOS AÑOS') AS ano,
    SUM(f.cantidad_casos) AS total_casos
FROM dbo.Fact_Vigilancia_Epidemiologica f
JOIN dbo.Dim_Enfermedad e ON f.id_enfermedad = e.id_enfermedad
JOIN dbo.Dim_Paciente p ON f.id_paciente = p.id_paciente
JOIN dbo.Dim_Tiempo t ON f.id_tiempo = t.id_tiempo
GROUP BY CUBE (e.nombre_enfermedad, p.curso_vida_minsa, t.ano);
GO

SELECT 
    t.ano,
    t.trimestre,
    t.nombre_mes,
    t.semana_epidemiologica,
    SUM(f.cantidad_casos) AS casos_notificados
FROM dbo.Fact_Vigilancia_Epidemiologica f
JOIN dbo.Dim_Tiempo t ON f.id_tiempo = t.id_tiempo
GROUP BY t.ano, t.trimestre, t.nombre_mes, t.semana_epidemiologica
ORDER BY t.ano DESC, t.semana_epidemiologica ASC;
GO

SELECT 
    u.provincia,
    e.nombre_enfermedad,
    p.curso_vida_minsa,
    SUM(f.cantidad_casos) AS casos_graves_notificados
FROM dbo.Fact_Vigilancia_Epidemiologica f
JOIN dbo.Dim_Ubicacion u ON f.id_ubicacion = u.id_ubicacion
JOIN dbo.Dim_Enfermedad e ON f.id_enfermedad = e.id_enfermedad
JOIN dbo.Dim_Paciente p ON f.id_paciente = p.id_paciente
WHERE u.departamento = 'LA LIBERTAD' 
  AND f.es_caso_grave = 1
GROUP BY u.provincia, e.nombre_enfermedad, p.curso_vida_minsa
ORDER BY casos_graves_notificados DESC;
GO
