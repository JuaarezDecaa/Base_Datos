# DataSalud Perú - DIRESA La Libertad (CIIN1021P)

Proyecto integrador de base de datos segura, automatizada e inteligente para la gestión de datos abiertos del MINSA.

## 👥 Integrantes
- JOAQUIN MATHIAS CRUZADO ARROYO (N00467227)
- FABRIZIO MATHÍAS GOMEZ LLERENA (N00498473)
- ALINA JAQUELINE MIRANDA AMAYA  (N00476960)
- CARLOS ADRIAN PAREDES PACHERRE (N00483352)
- MATHIAS FELIPE RODRIGUEZ PIZAN (N00467212)

## 🛠️ Tecnologías Utilizadas
- **RDBMS:** Microsoft SQL Server 2022
- **NoSQL:** MongoDB
- **ETL:** Python 3.10+ (pandas, sqlalchemy)
- **Big Data:** Apache Spark (PySpark)
- **Visualización:** Power BI Desktop

## 📁 Estructura del Repositorio
- `01_automatizacion/`: Scripts DDL, procedimientos almacenados con control de transacciones y triggers de auditoría.
- `02_seguridad/`: Roles conformes a Ley N.° 29733, políticas de respaldo y optimización de índices.
- `03_nosql/`: Colección semiestructurada y operaciones CRUD en MongoDB.
- `04_bi_etl/`: Modelo dimensional (Kimball), pipeline ETL funcional y dashboard analítico.
- `05_bigdata/`: Notebook PySpark con análisis descriptivo masivo y benchmark de rendimiento.
- `docs/`: Matriz de trazabilidad e informe final en PDF.

## 🚀 Instrucciones de Ejecución
1. **Base de Datos Transaccional:** Ejecutar los scripts de `01_automatizacion/` en orden numérico en SQL Server.
2. **Seguridad:** Ejecutar `01_creacion_roles_permisos.sql` desde un usuario `sysadmin`.
3. **ETL y Data Warehouse:**
   ```bash
   pip install -r requirements.txt
   python 04_bi_etl/etl_pipeline.py