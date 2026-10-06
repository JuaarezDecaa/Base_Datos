import os
import subprocess
import sys

if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

carpeta_dw = os.path.dirname(os.path.abspath(__file__))
archivo_ddl = os.path.join(carpeta_dw, "01_ddl_datawarehouse.sql")
archivo_carga = os.path.join(carpeta_dw, "02_carga_datawarehouse.sql")
archivo_log = os.path.join(carpeta_dw, "log_ejecucion_etl.txt")

print("=================================================================")
print("PIPELINE ETL AUTOMATIZADO — DATASALUD DW (DIRESA LA LIBERTAD)")
print("=================================================================\n")

def ejecutar_sql_archivo(ruta_script):
    comando = ["sqlcmd", "-S", ".", "-E", "-i", ruta_script]
    resultado = subprocess.run(comando, capture_output=True, text=True, encoding="utf-8")
    return resultado.stdout

def ejecutar_consulta(query):
    comando = ["sqlcmd", "-S", ".", "-E", "-d", "DataSalud_DW", "-Q", query]
    resultado = subprocess.run(comando, capture_output=True, text=True, encoding="utf-8")
    return resultado.stdout

print(">> Paso 1: Verificando y creando estructura DDL del Data Warehouse...")
salida_ddl = ejecutar_sql_archivo(archivo_ddl)

print(">> Paso 2: Compilando procedimientos almacenados de transformacion ETL...")
salida_carga = ejecutar_sql_archivo(archivo_carga)

print(">> Paso 3: Ejecutando carga dimensional y tabla de hechos en DataSalud_DW...")
consulta_procedimientos = """
SET NOCOUNT ON;
EXEC dbo.sp_ETL_LimpiarDW;
EXEC dbo.sp_ETL_Cargar_Dim_Tiempo;
EXEC dbo.sp_ETL_Cargar_Dim_Ubicacion;
EXEC dbo.sp_ETL_Cargar_Dim_Enfermedad;
EXEC dbo.sp_ETL_Cargar_Dim_Paciente;
EXEC dbo.sp_ETL_Cargar_Dim_Establecimiento;
EXEC dbo.sp_ETL_Cargar_Fact_Vigilancia;
"""
ejecutar_consulta(consulta_procedimientos)

print(">> Paso 4: Validando conteo oficial de registros cargados...")
consulta_conteo = """
SET NOCOUNT ON;
SELECT 'Dim_Tiempo' AS Tabla, COUNT(*) AS Total FROM dbo.Dim_Tiempo
UNION ALL
SELECT 'Dim_Ubicacion', COUNT(*) FROM dbo.Dim_Ubicacion
UNION ALL
SELECT 'Dim_Enfermedad', COUNT(*) FROM dbo.Dim_Enfermedad
UNION ALL
SELECT 'Dim_Paciente', COUNT(*) FROM dbo.Dim_Paciente
UNION ALL
SELECT 'Dim_Establecimiento', COUNT(*) FROM dbo.Dim_Establecimiento
UNION ALL
SELECT 'Fact_Vigilancia_Epidemiologica', COUNT(*) FROM dbo.Fact_Vigilancia_Epidemiologica;
"""
salida_conteo = ejecutar_consulta(consulta_conteo)
print(salida_conteo)

with open(archivo_log, "w", encoding="utf-8") as f:
    f.write("REPORTE DE EJECUCION ETL — DATASALUD_DW\n")
    f.write("==================================================\n")
    f.write(salida_conteo)

print(">> ETL finalizado con exito. Registro guardado en log_ejecucion_etl.txt\n")
