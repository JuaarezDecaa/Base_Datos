import os
import pandas as pd

ruta_carpeta = os.path.dirname(os.path.abspath(__file__))
archivo_salida = os.path.join(ruta_carpeta, "diagnostico_calidad_resultado.txt")

archivos = [
    ("Dengue (Muestra)", "muestra_dengue_minsa.csv", ";"),
    ("Leishmaniasis (Muestra)", "muestra_leishmaniosis_minsa.csv", ","),
    ("Dengue (Completo 2000-2024)", "datos_abiertos_vigilancia_dengue_2000_2024.csv", ";"),
    ("Leishmaniasis (Completo 2000-2024)", "datos_abiertos_vigilancia_leishmaniosis_2000_2024.csv", ",")
]

reporte = [
    "================================================================",
    "REPORTE CUANTIFICADO DE DIAGNOSTICO DE CALIDAD DE DATOS (MINSA)",
    "================================================================\n"
]

for nombre, archivo, separador in archivos:
    ruta_archivo = os.path.join(ruta_carpeta, archivo)
    if not os.path.exists(ruta_archivo):
        continue

    df = pd.read_csv(ruta_archivo, sep=separador, encoding="utf-8", dtype=str, on_bad_lines="skip")
    total_filas = len(df)

    nulos_localcod = (df["localcod"].fillna("").str.strip() == "").sum()
    nulos_localidad = (df["localidad"].fillna("").str.strip() == "").sum()
    nulos_diresa = (df["diresa"].fillna("").str.strip() == "").sum()
    duplicados = df.duplicated().sum()

    reporte.append(f"Dataset: {nombre}")
    reporte.append(f"Total de registros analizados: {total_filas:,}")
    reporte.append("----------------------------------------------------------------")
    reporte.append(f"1. Valores vacios o nulos en 'localcod':   {nulos_localcod:,} ({round(nulos_localcod / total_filas * 100, 2)}%)")
    reporte.append(f"2. Valores vacios o nulos en 'localidad':  {nulos_localidad:,} ({round(nulos_localidad / total_filas * 100, 2)}%)")
    reporte.append(f"3. Valores vacios o nulos en 'diresa':    {nulos_diresa:,} ({round(nulos_diresa / total_filas * 100, 2)}%)")
    reporte.append(f"4. Registros exactamente duplicados:      {duplicados:,} ({round(duplicados / total_filas * 100, 2)}%)\n")

with open(archivo_salida, "w", encoding="utf-8") as f:
    f.write("\n".join(reporte))

print("Diagnóstico completado exitosamente. Resultados guardados en diagnostico_calidad_resultado.txt")
