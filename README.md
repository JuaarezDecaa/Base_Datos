# DataSalud Perú — DIRESA La Libertad
## Sistema Integrado de Base de Datos Segura, Automatizada y Analítica (MINSA)

**Curso:** Bases de Datos Avanzadas y Big Data (CIIN1021P) | Ciclo 2026-2  
**Institución:** Universidad Privada del Norte (UPN)  
**Grupo:** Grupo 5  

### Integrantes del Equipo
* CRUZADO ARROYO, JOAQUIN MATHIAS (N00467227)
* GOMEZ LLERENA, FABRIZIO MATHÍAS (N00498473)
* MIRANDA AMAYA, ALINA JAQUELINE (N00476960)
* PAREDES PACHERRE, CARLOS ADRIAN (N00483352)
* RODRIGUEZ PIZAN, MATHIAS FELIPE (N00467212)

---

## 📌 ¿De qué trata el proyecto?
El proyecto implementa una solución de datos de extremo a extremo para la **DIRESA La Libertad** que automatiza la ingesta, garantiza la seguridad bajo la **Ley N.° 29733** y transforma los microdatos abiertos de **Dengue y Leishmaniasis** del MINSA en evidencia interactiva para la toma de decisiones sanitarias.

---

## 📁 Estructura Oficial del Repositorio (8 Carpetas)

Cada carpeta contiene su propio archivo explicativo `README.md`:

```text
Grupo5_CIIN1021P_EF_REPO/
│
├── 01_datos/             --> Microdatos oficiales MINSA, muestras y diagnóstico de calidad
├── 02_automatizacion/    --> DDL, SPs, triggers de auditoría/integridad y pruebas en SQL Server
├── 03_seguridad/         --> Roles (Ley 29733), políticas de respaldo, restore y optimización
├── 04_nosql/             --> Colección, JSON y operaciones CRUD en MongoDB
├── 05_dw_etl/            --> Modelo dimensional (Kimball), DDL, SSIS y ETL en Python
├── 06_dashboard/         --> Dashboard en Power BI Desktop, consultas OLAP en SQL y medidas DAX
├── 07_bigdata/           --> Notebook PySpark, script y comparativa de escalabilidad
├── 08_documentacion/     --> Informe técnico ([1.1]-[1.9]), diapositivas y matriz ética
│
├── 00_borrar_bases_de_datos.sql  --> Script para reiniciar el entorno en SQL Server
├── Grupo5_CIIN1021P_EF.pdf      --> 📕 INFORME TÉCNICO FINAL OFICIAL (PDF listo para entrega)
├── Grupo5_CIIN1021P_EF_PRES.pptx --> 📊 PRESENTACIÓN OFICIAL DE DIAPOSITIVAS (PPTX para la sustentación)
├── informacion.md               --> 📘 Explicación general de todo el proyecto y preguntas frecuentes
├── requirements.txt              --> Dependencias de Python (pymongo, pandas)
└── setup.py                      --> Script instalador de dependencias
```

> 💡 **Para una explicación detallada y sencilla de todo el proyecto, consulta [informacion.md](informacion.md).**


---

## 🚀 Guía Rápida de Ejecución

### Paso 0: Dependencias de Python
```bash
python setup.py
```

### Paso 1: Diagnóstico de Calidad de Datos
```bash
python 01_datos/diagnostico_calidad.py
```

### Paso 2: Base de Datos y Automatización (SQL Server)
En **SQL Server Management Studio (SSMS)**, conéctate a tu servidor local y ejecuta en orden:
1. `02_automatizacion/01_ddl_tablas_y_log.sql` (Crea la base de datos y tablas).
2. `02_automatizacion/02_stored_procedures.sql` (Crea funciones, triggers y procedimientos).
3. `02_automatizacion/03_pruebas_automatizacion.sql` (Ejecuta las pruebas transaccionales).
4. `02_automatizacion/04_carga_datos_csv.sql` *(Opcional)* (Carga los datos completos por Bulk Insert).

### Paso 3: Seguridad, Respaldos e Índices
En SSMS, ejecuta en orden:
1. `03_seguridad/01_roles_y_permisos.sql` (Crea roles, logins y valida permisos).
2. `03_seguridad/02_politica_respaldo.sql` (Genera respaldos Full y Diferencial).
3. `03_seguridad/03_restauracion_prueba.sql` (Prueba la restauración en base de prueba).
4. `03_seguridad/04_optimizacion_indices.sql` (Crea el índice y mide la aceleración).

### Paso 4: NoSQL con MongoDB
Con el servicio de MongoDB iniciado:
```bash
python 04_nosql/operaciones_crud_mongodb.py
```
*(O ejecuta `04_nosql/operaciones_crud_mongodb.js` desde mongosh)*.

### Paso 5: Data Warehouse y Proceso ETL
* **Opción rápida por terminal:**
  ```bash
  python 05_dw_etl/etl_python_simple.py
  ```
* **Opción visual en Visual Studio:**
  Abre `05_dw_etl/ETL/ETL.slnx`, abre `Package.dtsx` y presiona **Iniciar (F5)**.

### Paso 6: Dashboard y Operaciones OLAP (Power BI)
* Abre tu ventana de **Power BI Desktop** (el modelo ya está conectado y cargado con todas sus tablas, relaciones y medidas DAX).
* Sigue los pasos de `06_dashboard/guia_powerbi_desktop.md` para colocar los visuales y guarda el archivo como `06_dashboard/DataSalud_Dashboard.pbix`.
* Para ejecutar las consultas OLAP en SQL Server, abre `06_dashboard/consultas_olap_sql.sql` en SSMS.

### Paso 7: Procesamiento Big Data con PySpark
* Ejecuta el script de análisis y benchmark:
  ```bash
  python 07_bigdata/analisis_bigdata_script.py
  ```
* O abre el notebook interactivo `07_bigdata/analisis_bigdata_pyspark.ipynb` en VS Code o Jupyter.

### Paso 8: Documentación y Sustentación
Revisa la carpeta `08_documentacion/`:
* `informe_tecnico_completo.md`: Informe final estructurado de la sección [1.1] a [1.9].
* `guia_diapositivas_sustentacion.md`: Guía de las 12 diapositivas para la exposición de 15 minutos.
* `matriz_trazabilidad.md`: Matriz que conecta logros, temas, entregables y rúbrica.
* `reflexion_etica_y_curricular.md`: Dilemas éticos y articulación curricular.
* `declaracion_uso_ia.md`: Formato institucional de declaración de uso de IA.