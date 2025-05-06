#!/usr/bin/env python3

import requests
import statistics
from tabulate import tabulate
import time

# Configuración
URL_BASE = "http://localhost:8000/query"
ENGINES = ["mysql", "mongodb"]
QUERY_IDS = range(1, 9)
REPETICIONES = 25
TIMEOUT = 5  # segundos

# Resultados almacenados como: {(engine, query_id): [listado de time_ms]}
resultados = {}

for engine in ENGINES:
    for query_id in QUERY_IDS:
        key = (engine, query_id)
        tiempos = []
        print(f"Ejecutando {REPETICIONES} muestras para {engine} - Query {query_id}...")
        for i in range(REPETICIONES):
            url = f"{URL_BASE}/{engine}/{query_id}"
            try:
                inicio = time.perf_counter()
                resp = requests.get(url, timeout=TIMEOUT)
                duracion = (time.perf_counter() - inicio) * 1000  # por si time_ms no llega

                if resp.status_code == 200:
                    data = resp.json()
                    if "time_ms" in data:
                        tiempos.append(data["time_ms"])
                    else:
                        tiempos.append(duracion)  # respaldo por si falta campo
                else:
                    print(f"  [!] Respuesta HTTP {resp.status_code} omitida")
            except requests.RequestException as e:
                print(f"  [!] Error de red en intento {i + 1}: {e}")
        resultados[key] = tiempos

# Preparar tabla
tabla = []
for (engine, query_id), tiempos in sorted(resultados.items(), key=lambda x: (x[0][1], x[0][0])):
    if tiempos:
        promedio = round(statistics.mean(tiempos), 2)
        minimo = round(min(tiempos), 2)
        maximo = round(max(tiempos), 2)
        muestras = len(tiempos)
    else:
        promedio = minimo = maximo = "N/A"
        muestras = 0
    tabla.append([query_id, engine, promedio, minimo, maximo, muestras])

# Mostrar resultados
print("\nResumen de Benchmark:")
tabla_formateada = tabulate(tabla, headers=["Query", "Motor", "Promedio (ms)", "Mínimo (ms)", "Máximo (ms)", "Muestras"], tablefmt="github")
print(tabla_formateada)

# Guardar resultados en un archivo
with open("benchmark.txt", "w") as archivo:
    archivo.write("Resumen de Benchmark:\n")
    archivo.write(tabla_formateada + "\n\n")

# Análisis del mejor motor según los promedios
promedios_por_motor = {}
for (engine, _), tiempos in resultados.items():
    if tiempos:
        if engine not in promedios_por_motor:
            promedios_por_motor[engine] = []
        promedios_por_motor[engine].extend(tiempos)

mejor_motor = None
mejor_promedio = float('inf')
for motor, tiempos in promedios_por_motor.items():
    promedio_motor = statistics.mean(tiempos)
    print(f"Promedio general para {motor}: {round(promedio_motor, 2)} ms")
    if promedio_motor < mejor_promedio:
        mejor_promedio = promedio_motor
        mejor_motor = motor

if mejor_motor:
    mejor_motor_texto = f"\nEl mejor motor según los promedios es: {mejor_motor} con un promedio de {round(mejor_promedio, 2)} ms"
    print(mejor_motor_texto)
    with open("benchmark.txt", "a") as archivo:
        archivo.write(mejor_motor_texto + "\n")
else:
    no_datos_texto = "\nNo se pudo determinar el mejor motor debido a falta de datos."
    print(no_datos_texto)
    with open("benchmark.txt", "a") as archivo:
        archivo.write(no_datos_texto + "\n")
