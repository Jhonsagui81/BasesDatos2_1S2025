from cassandra.cluster import Cluster
from cassandra import ConsistencyLevel
from cassandra.query import SimpleStatement
import uuid
from datetime import datetime, timedelta
import random
import time

def insert_usuarios(session, num=100):
    usuarios = []
    insert_user = session.prepare("""
        INSERT INTO usuarios (id_usuario, nombre, email, dpi, telefono, nit_cf)
        VALUES (?, ?, ?, ?, ?, ?)
    """)
    for _ in range(num):
        user_id = uuid.uuid4()
        usuarios.append(user_id)
        session.execute(insert_user, (
            user_id,
            f"Usuario {random.randint(1, 1000)}",
            f"user{random.randint(1, 1000)}@mail.com",
            str(random.randint(1000000000000, 9999999999999)),
            f"5555-{random.randint(1000, 9999)}",
            f"NIT-{random.randint(10000, 99999)}"
        ))
    return usuarios

def insert_espacios(session, num=50):
    espacios = []
    insert_space = session.prepare("""
        INSERT INTO espacios (id_espacio, nombre, tipo, capacidad_maxima, ubicacion, estado)
        VALUES (?, ?, ?, ?, ?, ?)
    """)
    for _ in range(num):
        espacio_id = uuid.uuid4()
        espacios.append(espacio_id)
        session.execute(insert_space, (
            espacio_id,
            f"Sala {random.choice(['A', 'B', 'C'])}-{random.randint(1, 100)}",
            random.choice(["Conferencias", "Coworking", "Auditorio"]),
            random.randint(10, 100),
            f"Piso {random.randint(1, 5)}",
            "disponible"
        ))
    return espacios

def check_overlap(session, espacio_id, fecha, hora_inicio, hora_fin):
    """
    Revisa en la tabla reservas_por_espacio_fecha si existe alguna reserva en el mismo espacio 
    y fecha cuyo horario se solape con [hora_inicio, hora_fin).
    """
    query = SimpleStatement(
        """
        SELECT hora_inicio, hora_fin 
        FROM reservas_por_espacio_fecha
        WHERE id_espacio = %s AND fecha = %s
        """, 
        consistency_level=ConsistencyLevel.QUORUM
    )
    results = session.execute(query, (espacio_id, fecha))
    for row in results:
        # Condición: no hay superposición si la nueva reserva termina antes de que inicie la existente
        # o comienza después de que finalice la existente.
        if not (hora_fin <= row.hora_inicio or hora_inicio >= row.hora_fin):
            return True  # Hay solapamiento
    return False

def insert_reservation(session, usuario_id, espacio_id, fecha, hora_inicio, hora_fin, nombre_reserva):
    """
    Inserta la reserva en las cuatro tablas: reservas_por_espacio_fecha, reservas_por_usuario,
    reservas_por_fecha y disponibilidad_espacio. Se utiliza el mismo id de reserva para todas.
    """
    reserva_id = uuid.uuid1()  # Genera un TIMEUUID basado en el tiempo actual.
    
    insert_by_space = session.prepare("""
        INSERT INTO reservas_por_espacio_fecha
        (id_espacio, fecha, id_reserva, id_usuario, hora_inicio, hora_fin, estado)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """)
    insert_by_user = session.prepare("""
        INSERT INTO reservas_por_usuario
        (id_usuario, fecha, id_reserva, id_espacio, nombre_reserva, hora_fin, estado)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """)
    insert_by_fecha = session.prepare("""
        INSERT INTO reservas_por_fecha
        (fecha, id_espacio, id_reserva, id_usuario, hora_inicio, hora_fin, estado)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """)
    insert_disponibilidad = session.prepare("""
        INSERT INTO disponibilidad_espacio
        (id_espacio, fecha, hora_inicio, hora_fin, id_reserva)
        VALUES (?, ?, ?, ?, ?)
    """)
    try:
        session.execute(insert_by_space, (
            espacio_id,
            fecha,
            reserva_id,
            usuario_id,
            hora_inicio,
            hora_fin,
            "activa"
        ))
        session.execute(insert_by_user, (
            usuario_id,
            fecha,
            reserva_id,
            espacio_id,
            nombre_reserva,
            hora_fin.time(),
            "activa"
        ))
        session.execute(insert_by_fecha, (
            fecha,
            espacio_id,
            reserva_id,
            usuario_id,
            hora_inicio,
            hora_fin,
            "activa"
        ))
        session.execute(insert_disponibilidad, (
            espacio_id,
            fecha,
            hora_inicio,
            hora_fin,
            reserva_id
        ))
        return True
    except Exception as e:
        print(f"Error insertando reserva: {e}")
        return False

def main():
    # Configuración del clúster: asegúrate de usar las direcciones correctas o los nombres DNS que resuelvan.
    cluster = Cluster(['cassandra-node1', 'cassandra-node2', 'cassandra-node3'], port=9042)
    # Conectar al keyspace según lo que ves en cqlsh.
    session = cluster.connect("proyecto_1")
    
    # Inserción de usuarios y espacios.
    usuarios = insert_usuarios(session, num=100)
    espacios = insert_espacios(session, num=50)
    print("Usuarios y espacios insertados.")
    
    # Espera corta para garantizar que las inserciones anteriores se propagaron.
    time.sleep(5)
    
    # Insertar reservas: en este ejemplo se intentan insertar 100 reservas.
    num_reservas = 100  # Puedes escalar este número según lo necesites.
    for i in range(num_reservas):
        usuario_id = random.choice(usuarios)
        espacio_id = random.choice(espacios)
        
        # Generar una fecha aleatoria en octubre 2025
        fecha = datetime(2025, 10, 1) + timedelta(days=random.randint(0, 30))
        fecha_only = fecha.date()
        
        # Generar una hora de inicio entre las 8:00 y las 17:00
        start_hour = random.randint(8, 17)
        hora_inicio = datetime(fecha.year, fecha.month, fecha.day, start_hour, 0)
        duracion = random.randint(1, 3)  # Duración de la reserva entre 1 y 3 horas
        hora_fin = hora_inicio + timedelta(hours=duracion)
        
        # Validar que no exista superposición en el mismo espacio y fecha.
        if check_overlap(session, espacio_id, fecha_only, hora_inicio, hora_fin):
            print(f"Reserva {i+1} solapada en espacio {espacio_id}. Saltando...")
            continue
        
        # Definir un nombre para la reserva; aquí se utiliza el identificador del espacio (podrías buscar el nombre real)
        nombre_reserva = f"Reserva en espacio {espacio_id}"
        
        if insert_reservation(session, usuario_id, espacio_id, fecha_only, hora_inicio, hora_fin, nombre_reserva):
            print(f"Reserva {i+1} insertada correctamente.")
        else:
            print(f"Fallo al insertar la reserva {i+1}.")
    
    cluster.shutdown()

if __name__ == "__main__":
    main()
