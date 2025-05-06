import os
import json
import pandas as pd
import pymysql
from pymongo import MongoClient

# ---------------- CONFIGURACIÓN ----------------

MYSQL_CONFIG = {
    "host": "localhost",
    "user": "sbd2dev",
    "password": "sbd2dev",
    "charset": "utf8mb4",
    "autocommit": True
}
MYSQL_DB = "clinica_mysql"
MONGO_DB = "clinica_nosql"

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CARGA_DIR = os.path.join(BASE_DIR, "[BD2]Carga")

ARCHIVOS = {
    "Pacientes": os.path.join(CARGA_DIR, "Pacientes.xlsx"),
    "Habitaciones": os.path.join(CARGA_DIR, "Habitaciones.xlsx"),
    "LogHabitacion": os.path.join(CARGA_DIR, "LogHabitacion.xlsx"),
    "LogActividades1": os.path.join(CARGA_DIR, "LogActividades1.xlsx"),
    "LogActividades2": os.path.join(CARGA_DIR, "LogActividades2.xlsx")
}

# ---------------- MYSQL ----------------

def conectar_mysql():
    return pymysql.connect(**MYSQL_CONFIG)

def crear_bd_mysql():
    conn = conectar_mysql()
    with conn.cursor() as cur:
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {MYSQL_DB}")
        cur.execute(f"USE {MYSQL_DB}")
    return conn

def crear_tabla_mysql(conn, tabla, df):
    columnas_sql = []
    for col in df.columns:
        tipo = "VARCHAR(255)"
        if pd.api.types.is_integer_dtype(df[col]):
            tipo = "INT"
        elif pd.api.types.is_float_dtype(df[col]):
            tipo = "DOUBLE"
        elif pd.api.types.is_datetime64_any_dtype(df[col]):
            tipo = "DATETIME"
        columnas_sql.append(f"`{col}` {tipo}")
    schema = ", ".join(columnas_sql)
    with conn.cursor() as cur:
        cur.execute(f"DROP TABLE IF EXISTS `{tabla}`")
        cur.execute(f"CREATE TABLE `{tabla}` ({schema})")
    return columnas_sql

def insertar_datos_mysql(conn, tabla, df):
    if df.empty:
        print(f"[INFO] Tabla `{tabla}` está vacía. No se insertan datos.")
        return
    cols = ", ".join([f"`{col}`" for col in df.columns])
    placeholders = ", ".join(["%s"] * len(df.columns))
    sql = f"INSERT INTO `{tabla}` ({cols}) VALUES ({placeholders})"
    data = df.itertuples(index=False, name=None)
    with conn.cursor() as cur:
        cur.executemany(sql, data)
    conn.commit()
    print(f"[INFO] {len(df)} registros insertados en `{tabla}`.")

def mostrar_mysql_tablas(conn):
    with conn.cursor() as cur:
        cur.execute("SHOW TABLES")
        tablas = [t[0] for t in cur.fetchall()]
        print("\n--- MySQL: Vista previa de tablas ---")
        for tabla in tablas:
            print(f"\nTabla: {tabla}")
            cur.execute(f"SELECT * FROM `{tabla}` LIMIT 5")
            for fila in cur.fetchall():
                print(fila)

# ---------------- MONGODB ----------------

def cargar_datos_mongodb(client, nombre_db, datos):
    db = client[nombre_db]
    modelo = {}
    for nombre_coleccion, df in datos.items():
        print(f"[INFO] Procesando colección MongoDB: {nombre_coleccion}...")
        db[nombre_coleccion].drop()
        if not df.empty:
            db[nombre_coleccion].insert_many(df.to_dict(orient='records'))
            print(f"[INFO] {len(df)} documentos insertados en `{nombre_coleccion}`.")
        else:
            print(f"[INFO] Colección `{nombre_coleccion}` vacía. No se insertan documentos.")

        campos = {}
        for col in df.columns:
            if pd.api.types.is_integer_dtype(df[col]):
                tipo = "int"
            elif pd.api.types.is_float_dtype(df[col]):
                tipo = "float"
            elif pd.api.types.is_datetime64_any_dtype(df[col]):
                tipo = "datetime"
            else:
                tipo = "string"
            campos[col] = tipo
        modelo[nombre_coleccion] = campos

    json_path = os.path.join(BASE_DIR, "mongodbmodel.json")
    with open(json_path, "w", encoding="utf-8") as f_json:
        json.dump(modelo, f_json, indent=4)
    print(f"[INFO] Esquema MongoDB exportado a: {json_path}")

def mostrar_mongodb_colecciones(client):
    db = client[MONGO_DB]
    print("\n--- MongoDB: Vista previa de colecciones ---")
    for nombre in db.list_collection_names():
        print(f"\nColección: {nombre}")
        for doc in db[nombre].find({}, limit=5):
            print(doc)

# ---------------- EJECUCIÓN ----------------

def main():
    # Selección de modo
    modo = input("Modo de ejecución [dev|prod]: ").strip().lower()
    if modo not in ["dev", "prod"]:
        print("Modo inválido. Use 'dev' o 'prod'.")
        return
    max_filas = 100 if modo == "dev" else None
    print(f"[INFO] Ejecutando en modo: {modo.upper()}")

    # Cargar archivos
    datos = {}
    for nombre, ruta in ARCHIVOS.items():
        print(f"[INFO] Cargando archivo: {ruta}")
        if not os.path.exists(ruta):
            raise FileNotFoundError(f"Archivo no encontrado: {ruta}")
        df = pd.read_excel(ruta).fillna("")
        if max_filas:
            df = df.head(max_filas)
        datos[nombre] = df

    # Eliminar base de datos MySQL si existe
    print(f"[INFO] Eliminando base de datos MySQL `{MYSQL_DB}`...")
    conn_tmp = conectar_mysql()
    with conn_tmp.cursor() as cur:
        cur.execute(f"DROP DATABASE IF EXISTS {MYSQL_DB}")
    conn_tmp.close()

    # Eliminar base de datos MongoDB si existe
    print(f"[INFO] Eliminando base de datos MongoDB `{MONGO_DB}`...")
    client_mongo = MongoClient("mongodb://localhost:27017/")
    client_mongo.drop_database(MONGO_DB)
    client_mongo.close()

    # Crear y cargar MySQL
    print("[INFO] Creando base de datos MySQL y cargando tablas...")
    conn_mysql = crear_bd_mysql()
    sql_path = os.path.join(BASE_DIR, "mysqlmodel.sql")
    with open(sql_path, "w", encoding="utf-8") as f_sql:
        for nombre, df in datos.items():
            print(f"[INFO] Procesando tabla MySQL: {nombre}...")
            columnas_sql = crear_tabla_mysql(conn_mysql, nombre, df)
            f_sql.write(f"DROP TABLE IF EXISTS `{nombre}`;\n")
            f_sql.write(f"CREATE TABLE `{nombre}` ({', '.join(columnas_sql)});\n\n")
            insertar_datos_mysql(conn_mysql, nombre, df)
    print(f"[INFO] Esquema SQL exportado a: {sql_path}")
    mostrar_mysql_tablas(conn_mysql)
    conn_mysql.close()

    # Crear y cargar MongoDB
    print("[INFO] Creando base de datos MongoDB y cargando colecciones...")
    client_mongo = MongoClient("mongodb://localhost:27017/")
    cargar_datos_mongodb(client_mongo, MONGO_DB, datos)
    mostrar_mongodb_colecciones(client_mongo)
    client_mongo.close()

    print(f"\n[SUCCESS] Carga completada en modo: {modo.upper()}.")

if __name__ == "__main__":
    main()
