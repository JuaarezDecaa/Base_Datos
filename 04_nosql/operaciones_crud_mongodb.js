use DataSaludNoSQL;

db.atenciones_clinicas.drop();

db.atenciones_clinicas.insertMany([
  {
    "id_atencion": "AT-2024-00101",
    "fecha_atencion": new Date("2024-04-12T09:30:00Z"),
    "departamento": "LA LIBERTAD",
    "provincia": "TRUJILLO",
    "distrito": "EL PORVENIR",
    "establecimiento": "HOSPITAL SANTA ISABEL",
    "enfermedad": "DENGUE CON SIGNOS DE ALARMA",
    "cie10": "A97.1",
    "paciente": { "edad": 28, "tipo_edad": "A", "sexo": "F", "etapa_vida": "JOVEN" },
    "datos_clinicos": {
      "dias_fiebre": 4,
      "temperatura_axilar": 39.2,
      "plaquetas": 85000,
      "hematocrito": 44.5,
      "signos_alarma": ["Dolor abdominal intenso y continuo", "Vómitos persistentes"],
      "requiere_hospitalizacion": true,
      "cama_asignada": "C-14",
      "evolucion_favorable": false
    },
    "seguimiento_epidemiologico": { "visita_domiciliaria": true, "responsable_notificacion": "Lic. M. Cruzado" }
  },
  {
    "id_atencion": "AT-2024-00102",
    "fecha_atencion": new Date("2024-04-14T11:15:00Z"),
    "departamento": "LA LIBERTAD",
    "provincia": "CHEPEN",
    "distrito": "PACANGA",
    "establecimiento": "PUESTO DE SALUD PACANGA",
    "enfermedad": "LEISHMANIASIS CUTANEA",
    "cie10": "B55.1",
    "paciente": { "edad": 35, "tipo_edad": "A", "sexo": "M", "etapa_vida": "ADULTO" },
    "datos_clinicos": {
      "tiempo_enfermedad_meses": 2,
      "tipo_lesion": "Ulcera de bordes elevados e indurados",
      "ubicacion_lesion": ["Brazo izquierdo", "Oreja derecha"],
      "numero_lesiones": 2,
      "frotis_directo_leishmania": "POSITIVO",
      "tratamiento_indicado": { "medicamento": "Antimoniato de meglumina", "dosis_mg_dia": 1200, "duracion_dias": 20 }
    },
    "seguimiento_epidemiologico": { "zona_transmision_probable": "Caserío Huaca Blanca", "responsable_notificacion": "Dr. C. Paredes" }
  },
  {
    "id_atencion": "AT-2024-00103",
    "fecha_atencion": new Date("2024-04-16T14:40:00Z"),
    "departamento": "LA LIBERTAD",
    "provincia": "TRUJILLO",
    "distrito": "LA ESPERANZA",
    "establecimiento": "CENTRO DE SALUD JERUSALEN",
    "enfermedad": "DENGUE SIN SIGNOS DE ALARMA",
    "cie10": "A97.0",
    "paciente": { "edad": 15, "tipo_edad": "A", "sexo": "M", "etapa_vida": "ADOLESCENTE" },
    "datos_clinicos": {
      "dias_fiebre": 2,
      "temperatura_axilar": 38.4,
      "plaquetas": 195000,
      "hematocrito": 38.0,
      "signos_alarma": [],
      "requiere_hospitalizacion": false
    },
    "seguimiento_epidemiologico": { "visita_domiciliaria": false, "responsable_notificacion": "Dra. A. Miranda" }
  },
  {
    "id_atencion": "AT-2024-00104",
    "fecha_atencion": new Date("2024-04-18T16:20:00Z"),
    "departamento": "LA LIBERTAD",
    "provincia": "ASCOPE",
    "distrito": "CASA GRANDE",
    "establecimiento": "HOSPITAL CASA GRANDE",
    "enfermedad": "DENGUE GRAVE",
    "cie10": "A97.2",
    "paciente": { "edad": 62, "tipo_edad": "A", "sexo": "F", "etapa_vida": "ADULTO MAYOR" },
    "datos_clinicos": {
      "dias_fiebre": 5,
      "temperatura_axilar": 39.8,
      "plaquetas": 28000,
      "hematocrito": 51.2,
      "signos_alarma": ["Hipotensión severa", "Sangrado de mucosas", "Derrame pleural"],
      "requiere_hospitalizacion": true,
      "cama_asignada": "UCI-03",
      "evolucion_favorable": false
    },
    "seguimiento_epidemiologico": { "investigacion_brote_iniciada": true, "responsable_notificacion": "Dr. M. Rodriguez" }
  }
]);

print(">> [CREATE] Documentos insertados con éxito.");

print(">> [READ] Pacientes hospitalizados con signos de alarma:");
db.atenciones_clinicas.find(
  { "datos_clinicos.requiere_hospitalizacion": true },
  { "id_atencion": 1, "distrito": 1, "enfermedad": 1, "datos_clinicos.cama_asignada": 1, "datos_clinicos.signos_alarma": 1, "_id": 0 }
);

print(">> [UPDATE] Actualizando evolución clínica de AT-2024-00101:");
db.atenciones_clinicas.updateOne(
  { "id_atencion": "AT-2024-00101" },
  {
    $set: {
      "datos_clinicos.evolucion_favorable": true,
      "datos_clinicos.plaquetas": 135000,
      "datos_clinicos.observaciones_alta": "Paciente estable. Alta médica autorizada."
    }
  }
);

print(">> [DELETE] Eliminando registro descartado AT-2024-00103:");
db.atenciones_clinicas.deleteOne({ "id_atencion": "AT-2024-00103" });

print(">> Conteo final de documentos en la colección:");
db.atenciones_clinicas.countDocuments();
