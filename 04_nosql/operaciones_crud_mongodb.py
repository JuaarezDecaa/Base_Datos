import json
import os
import sys
import pymongo

if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

print(">> PASO 1: Conectando a MongoDB en mongodb://localhost:27017 ...")

try:
    cliente = pymongo.MongoClient("mongodb://localhost:27017/", serverSelectionTimeoutMS=2000)
    cliente.server_info()
except Exception as error:
    print(f"ERROR: No se pudo conectar a MongoDB. Asegúrate de que el servicio esté activo.\nDetalle: {error}")
    exit(1)

bd = cliente["DataSaludNoSQL"]
coleccion = bd["atenciones_clinicas"]

coleccion.drop()
print("   Base de datos: DataSaludNoSQL")
print("   Colección:     atenciones_clinicas (reiniciada correctamente)\n")

print(">> PASO 2: [CREATE] Insertando historias clínicas semiestructuradas...")

ruta_actual = os.path.dirname(os.path.abspath(__file__))
ruta_json = os.path.join(ruta_actual, "datos_atenciones_semiestructuradas.json")

with open(ruta_json, "r", encoding="utf-8") as archivo:
    datos_pacientes = json.load(archivo)

resultado_insert = coleccion.insert_many(datos_pacientes)
print(f"   Éxito: Se insertaron {len(resultado_insert.inserted_ids)} fichas clínicas con campos variables.\n")

print(">> PASO 3: [READ] Consultando pacientes que requieren hospitalización...")

filtro = {"datos_clinicos.requiere_hospitalizacion": True}

pacientes_graves = list(coleccion.find(filtro))

for p in pacientes_graves:
    id_caso = p.get("id_atencion")
    distrito = p.get("distrito")
    enf = p.get("enfermedad")
    cama = p.get("datos_clinicos", {}).get("cama_asignada")
    signos = p.get("datos_clinicos", {}).get("signos_alarma")
    print(f"   * Paciente {id_caso} ({enf}) en {distrito} -> Cama: {cama} | Signos: {signos}")
print()

print(">> PASO 4: [UPDATE] Actualizando evolución médica del paciente AT-2024-00101...")

coleccion.update_one(
    {"id_atencion": "AT-2024-00101"},
    {
        "$set": {
            "datos_clinicos.evolucion_favorable": True,
            "datos_clinicos.plaquetas": 135000,
            "datos_clinicos.observaciones_alta": "Paciente estable. Alta médica autorizada."
        }
    }
)

paciente_actualizado = coleccion.find_one({"id_atencion": "AT-2024-00101"})
clinico = paciente_actualizado["datos_clinicos"]
print(f"   Plaquetas recuperadas: {clinico['plaquetas']}")
print(f"   Evolución favorable:   {clinico['evolucion_favorable']}")
print(f"   Nota médica:           {clinico['observaciones_alta']}\n")

print(">> PASO 5: [DELETE] Eliminando la ficha descartada AT-2024-00103...")

resultado_delete = coleccion.delete_one({"id_atencion": "AT-2024-00103"})
print(f"   Registros eliminados: {resultado_delete.deleted_count}")

total_restante = coleccion.count_documents({})
print(f"   Total de historias clínicas activas en MongoDB: {total_restante}\n")

print("=============================================================================")
print("OPERACIONES CRUD EN MONGODB COMPLETADAS EXITOSAMENTE")
print("=============================================================================")
