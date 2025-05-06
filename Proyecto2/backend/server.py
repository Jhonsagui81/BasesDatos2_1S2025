from fastapi import FastAPI, HTTPException, Path
from fastapi.middleware.cors import CORSMiddleware
from typing import Literal
import pymysql
from pymongo import MongoClient
from time import perf_counter

app = FastAPI()

# Middleware CORS: aceptar cualquier origen
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración MySQL
MYSQL_CONFIG = {
    "host": "localhost",
    "user": "sbd2dev",
    "password": "sbd2dev",
    "database": "clinica_mysql"
}

# Configuración MongoDB
MONGO_URI = "mongodb://localhost:27017"
MONGO_DB = "clinica_nosql"

# Cliente MongoDB
mongo_client = MongoClient(MONGO_URI)
mongo_db = mongo_client[MONGO_DB]

# Conexión MySQL
def get_mysql_connection():
    return pymysql.connect(
        host=MYSQL_CONFIG["host"],
        user=MYSQL_CONFIG["user"],
        password=MYSQL_CONFIG["password"],
        database=MYSQL_CONFIG["database"],
        cursorclass=pymysql.cursors.DictCursor
    )

# Ruta principal de consulta
@app.get("/query/{engine}/{query_id}")
def run_query(
    engine: Literal["mysql", "mongodb"] = Path(..., description="Motor de base de datos"),
    query_id: int = Path(..., ge=1, le=8, description="ID de consulta (1 a 8)")
):
    if engine == "mysql":
        return execute_mysql_query(query_id)
    elif engine == "mongodb":
        return execute_mongo_query(query_id)

# Consultas SQL
def execute_mysql_query(query_id: int):
    queries = {
        1: """
            SELECT 
                CASE 
                    WHEN edad < 18 THEN 'Pediátrico'
                    WHEN edad BETWEEN 18 AND 60 THEN 'Mediana edad'
                    ELSE 'Geriátrico'
                END AS categoria_edad,
                COUNT(*) AS total
            FROM Pacientes
            GROUP BY categoria_edad;
        """,
        2: """
            SELECT H.habitacion, COUNT(DISTINCT LA.idPaciente) AS pacientes
            FROM LogActividades1 LA
            JOIN Habitaciones H ON H.idHabitacion = LA.idHabitacion
            GROUP BY H.habitacion;
        """,
        3: """
            SELECT genero, COUNT(*) AS total
            FROM Pacientes
            GROUP BY genero;
        """,
        4: """
            SELECT edad, COUNT(*) AS total
            FROM Pacientes
            GROUP BY edad
            ORDER BY total DESC
            LIMIT 5;
        """,
        5: """
            SELECT edad, COUNT(*) AS total
            FROM Pacientes
            GROUP BY edad
            ORDER BY total ASC
            LIMIT 5;
        """,
        6: """
            SELECT H.habitacion, COUNT(*) AS uso
            FROM LogActividades1 LA
            JOIN Habitaciones H ON H.idHabitacion = LA.idHabitacion
            GROUP BY H.habitacion
            ORDER BY uso DESC
            LIMIT 5;
        """,
        7: """
            SELECT H.habitacion, COUNT(*) AS uso
            FROM LogActividades1 LA
            JOIN Habitaciones H ON H.idHabitacion = LA.idHabitacion
            GROUP BY H.habitacion
            ORDER BY uso ASC
            LIMIT 5;
        """,
        8: """
            SELECT DATE(timestamp) AS dia, COUNT(DISTINCT idPaciente) AS total
            FROM LogActividades1
            GROUP BY dia
            ORDER BY total DESC
            LIMIT 1;
        """
    }
    query = queries.get(query_id)
    if not query:
        raise HTTPException(status_code=400, detail="Consulta no definida")

    try:
        with get_mysql_connection() as conn:
            with conn.cursor() as cursor:
                t0 = perf_counter()
                cursor.execute(query)
                rows = cursor.fetchall()
                t1 = perf_counter()
                return {
                    "time_ms": round((t1 - t0) * 1000, 3),
                    "result": rows
                }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Consultas MongoDB
def execute_mongo_query(query_id: int):
    if query_id == 1:
        t0 = perf_counter()
        categorias = {"Pediátrico": 0, "Mediana edad": 0, "Geriátrico": 0}
        for doc in mongo_db.Pacientes.find({}, {"edad": 1}):
            edad = doc.get("edad", 0)
            if edad < 18:
                categorias["Pediátrico"] += 1
            elif edad <= 60:
                categorias["Mediana edad"] += 1
            else:
                categorias["Geriátrico"] += 1
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": categorias}

    elif query_id == 2:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$idHabitacion", "pacientes": {"$addToSet": "$idPaciente"}}},
            {"$project": {"habitacion": "$_id", "total": {"$size": "$pacientes"}}}
        ]
        result = list(mongo_db.LogActividades1.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 3:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$genero", "total": {"$sum": 1}}},
            {"$project": {"genero": "$_id", "total": 1, "_id": 0}}
        ]
        result = list(mongo_db.Pacientes.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 4:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$edad", "total": {"$sum": 1}}},
            {"$sort": {"total": -1}},
            {"$limit": 5}
        ]
        result = list(mongo_db.Pacientes.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 5:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$edad", "total": {"$sum": 1}}},
            {"$sort": {"total": 1}},
            {"$limit": 5}
        ]
        result = list(mongo_db.Pacientes.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 6:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$idHabitacion", "uso": {"$sum": 1}}},
            {"$sort": {"uso": -1}},
            {"$limit": 5}
        ]
        result = list(mongo_db.LogActividades1.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 7:
        t0 = perf_counter()
        pipeline = [
            {"$group": {"_id": "$idHabitacion", "uso": {"$sum": 1}}},
            {"$sort": {"uso": 1}},
            {"$limit": 5}
        ]
        result = list(mongo_db.LogActividades1.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    elif query_id == 8:
        t0 = perf_counter()
        pipeline = [
            {"$group": {
                "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$timestamp"}},
                "pacientes": {"$addToSet": "$idPaciente"}
            }},
            {"$project": {"dia": "$_id", "total": {"$size": "$pacientes"}}},
            {"$sort": {"total": -1}},
            {"$limit": 1}
        ]
        result = list(mongo_db.LogActividades1.aggregate(pipeline))
        t1 = perf_counter()
        return {"time_ms": round((t1 - t0) * 1000, 3), "result": result}

    raise HTTPException(status_code=400, detail="Consulta no implementada")
