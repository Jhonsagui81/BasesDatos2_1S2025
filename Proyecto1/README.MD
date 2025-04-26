# DOCUMENTACION 
## Docker Compose
**Service**
Aqui se definen los contenedores. los contenedores que se van a levantar, para este caso se necesitaran 3 nodos.
1. **cassandra-node1**
build: ./cassandra Le dice a Docker que construya la imagen usando el contexto y el Dockerfile ubicados en la carpeta ./cassandra. Esto permite personalizar la imagen de Cassandra.

    **container_name**: cassandra-node1 Establece el nombre del contenedor, facilitando la identificación y administración de este nodo.

    **networks**: El nodo se conecta a la red definida como cassandra-net, lo que permite que se comunique fácilmente con los otros nodos del clúster.

    **volumes**: Se monta el volumen cassandra-data-node1 en la ruta /var/lib/cassandra. Esto asegura que los datos de Cassandra se persistan en el host, de manera que si el contenedor se reinicia, la información permanece.

    **environment**: Se definen las variables de entorno que configuran Cassandra:

    **CASSANDRA_SEEDS**: Lista que indica los nodos semilla (seed nodes) del clúster, aquí se listan los tres nodos. Los seeds son fundamentales para que los demás nodos descubran el clúster y se unan a él.

    **CASSANDRA_CLUSTER_NAME**: Define el nombre del clúster, en este caso "Proyecto1_Cluster". Es importante que todos los nodos pertenezcan al mismo clúster.

    **CASSANDRA_ENDPOINT_SNITCH**: Usa GossipingPropertyFileSnitch, que es una configuración recomendada en entornos de múltiples datacenters para gestionar la topología de red.

    **CASSANDRA_DC**: Define el datacenter (en este caso "dc1"). Esto es útil para tener configuraciones más avanzadas y de rendimiento en entornos distribuidos.

    **ports**: Mapea el puerto 9042 del contenedor al puerto 9042 del host. Este puerto es el puerto CQL (Cassandra Query Language) que se utiliza para interactuar con Cassandra.

### Red y Volúmenes
**networks**: Se crea una red personalizada llamada cassandra-net utilizando el controlador bridge. Esto permite que los contenedores se comuniquen entre sí sin exponer innecesariamente puertos al exterior.

**volumes**: Se definen tres volúmenes: uno para cada nodo. Estos volúmenes aseguran que la información almacenada en /var/lib/cassandra se conserve incluso si los contenedores se detienen o eliminan. Esto es fundamental para mantener la persistencia de la base de datos.

## Docker file
Este Dockerfile se basa en Cassandra 4.1, copia un script personalizado de configuración (setup.sh) al contenedor, le asigna permisos de ejecución y lo establece como el comando de inicio. Esto permite que cada vez que inicies un contenedor basado en esta imagen, se ejecute el script que puede configurar, ajustar o inicializar Cassandra según las necesidades de tu proyecto.

## Script
 Utilizan el comando sed para buscar y reemplazar líneas específicas en el archivo de configuración de Cassandra:
 Ajusta la configuración de Cassandra según las variables de entorno, permitiendo personalizar valores cruciales como el nombre del clúster, los nodos semilla y cómo se detecta la topología.

1. Asegura la persistencia de la configuración sin necesidad de editar manualmente el archivo de configuración cada vez que se inicia el contenedor.

2. Inicia el proceso principal de Cassandra (a través de docker-entrypoint.sh) de forma que el contenedor se comporte como en la imagen oficial pero con los ajustes personalizados.

# COMANDOS
Ejecurar docker compose
```bash
#Para levantar 
docker-compose up -d
#Para construir
docker-compose build
#para eliminar contenedores actuales
docker-compose down
```
Verificar estado de cluster
```bash
docker exec -it cassandra-node1 nodetool status #Deben estar los 3 levantados
```
Entrar la nodo1 para scribir CQL 
```bash
docker exec -it cassandra-node1 cqlsh
```
Crear keyspace con replicacion y 3 nodos
```sql
CREATE KEYSPACE proyecto_1 
WITH replication = {
    'class': 'NetworkTopologyStrategy', 
    'dc1': 3
};
```
# MODELO CONCEPTUAL
- Entidades 
  - Usuarios:
    - id (PK)
    - nombre
    - email
    - dpi
    - telefono
    - nit
  - Espacios:
    - id (PK)
    - nombre
    - tipo
    - capacidad_max
    - ubicacio
  - Reservas:
    - id (PK)
    - usuario_id
    - espacio_id
    - fecha
    - hora_inicio
    - hora_fin
    - estado
- Relaciones:
  - Un **usuario** puede tener muchas **Reservas**
  - Un **espacio** puede tener muchas **Reservas**, pero no puede estar reservado por mas de un usuario en el mismo horario
# MODELO LOGICO

**Tabla 1: Disponibilidad por espacio y fecha**
El proposito de esta tabla es consultar horarios ocupados de un espacio en una fecha especifica. Las claves de particion son **espacio_id**, **fecha** para distribuir por espacio y fecha. La llave de cluster es **hora_inicio** para ordenar por horario
```sql
USE proyecto_1;

CREATE TABLE disponibilidad_espacio (
    espacio_id UUID,
    fecha DATE,
    hora_inicio TIME,
    hora_fin TIME,
    reserva_id UUID,
    usuario_id UUID,
    estado TEXT,
    PRIMARY KEY ((espacio_id, fecha), hora_inicio)
) WITH CLUSTERING ORDER BY (hora_inicio ASC);
```

**Tabla 2: Historial de reservas por usuario**
El proposito de esta tabla es obtener todas las reservas de un usuario. La clave de particion va a ser **usuario_id** para agrupar todas sus reservas y la llave de cluster seran **fecha** y **hora_inicio** para ordenar cronologicamente.
```sql
CREATE TABLE historial_usuario (
    usuario_id UUID,
    fecha DATE,
    hora_inicio TIME,
    espacio_id UUID,
    hora_fin TIME,
    estado TEXT,
    PRIMARY KEY (usuario_id, fecha, hora_inicio)
);
```

**Tabla 3: Ocupacion por rango de fechas**
El proposito de esta tabla es consultar la ocupacion de todos los espacios en un rango de fechas. La clave de particion va a ser la **fecha** para agrupar por dia. La llave de cluster va a ser el **espacio_id** y **hora_inicio** para ordenar por espacio y horario


# MODELO FISICO 

Configurar el KeySpace para el proyecto, Se configurro Replication Factor = 3 esto quiere decir que los datos se replican en los 3 nodos del cluster. Esto significa que si un nodo falla, los otros dos aun tienen la copia completa de los datos, lo que garantica **alta disponibilidad** y **toleracia a fallos**.

Tambien al tener los datos replicacion en los 3 nodos, las operaciones de lectura pueden distribuirse entre los nodos. Esto permite que las peticiones se sirvan desde la replica mas cercana o menos cargada, **reduciendo la latencia** y **mejorando el rendimiento**
```sql
CREATE KEYSPACE proyecto_1 
WITH replication = {
    'class': 'NetworkTopologyStrategy', 
    'dc1': 3
};
```

**TABLAS** 
```sql
CREATE TABLE usuarios (
    id_usuario UUID PRIMARY KEY,
    nombre TEXT,
    email TEXT,
    dpi TEXT,
    telefono TEXT,
    nit_cf TEXT 
);


CREATE TABLE proyecto_1.espacios (
    id_espacio UUID PRIMARY KEY,
    nombre TEXT,
    tipo TEXT,
    capacidad_maxima INT,
    ubicacion TEXT,
    estado TEXT  
);


CREATE TABLE proyecto_1.reservas_por_usuario (
    id_usuario UUID,
    fecha DATE,
    fecha_mes TEXT,
    id_reserva TIMEUUID, 
    id_espacio UUID,
    nombre_reserva TEXT,
    hora_fin TIME,      
    estado TEXT,       
    PRIMARY KEY ((id_usuario, fecha_mes), fecha, id_reserva)
) WITH CLUSTERING ORDER BY (fecha DESC, id_reserva DESC);


CREATE TABLE proyecto_1.reservas_por_espacio_fecha (
    id_espacio UUID,
    fecha DATE,
    id_reserva TIMEUUID,
    id_usuario UUID,
    hora_inicio TIMESTAMP, 
    hora_fin TIMESTAMP,
    estado TEXT,
    PRIMARY KEY ((id_espacio, fecha), id_reserva)
) WITH CLUSTERING ORDER BY (id_reserva ASC);


CREATE TABLE proyecto_1.reservas_por_fecha (
    fecha DATE,
    id_espacio UUID,     
    id_reserva TIMEUUID,
    id_usuario UUID,
    hora_inicio TIMESTAMP,
    hora_fin TIMESTAMP,
    estado TEXT,
    PRIMARY KEY ((fecha, id_espacio), hora_inicio, id_reserva)
) WITH CLUSTERING ORDER BY (hora_inicio ASC, id_reserva ASC);

--Para mejorar datos temporales se agrega compactacion
ALTER TABLE proyecto_1.reservas_por_fecha 
WITH compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 1
};


CREATE TABLE proyecto_1.disponibilidad_espacio (
    id_espacio UUID,
    fecha DATE,
    hora_inicio TIMESTAMP,
    hora_fin TIMESTAMP,
    id_reserva UUID,
    estado TEXT,  -- Nuevo campo
    PRIMARY KEY ((id_espacio, fecha), hora_inicio, estado)  -- Incluir estado como clustering key
) WITH CLUSTERING ORDER BY (hora_inicio ASC, estado ASC);


ALTER TABLE proyecto_1.disponibilidad_espacio 
WITH compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'HOURS',
    'compaction_window_size': 6
};


--VISTA MATERIALIZADA para busqueda por estado
CREATE MATERIALIZED VIEW proyecto_1.disponibilidad_por_estado AS
SELECT 
    id_espacio,
    fecha,
    hora_inicio,
    hora_fin,
    id_reserva,
    estado
FROM proyecto_1.disponibilidad_espacio
WHERE 
    estado IS NOT NULL 
    AND id_espacio IS NOT NULL 
    AND fecha IS NOT NULL 
    AND hora_inicio IS NOT NULL
PRIMARY KEY ((estado, id_espacio), fecha, hora_inicio)
WITH CLUSTERING ORDER BY (fecha ASC, hora_inicio ASC);

```
# INSERTCION DE DATOS
Se utilizo un script de python para poder lograr la carga masiva de datos utilizando **BATCH WRITES**, el escrip esta conformado por las siguientes funciones:
 - Insertar Usuarios:
    Esta funcion prepara un query para insertar datos en la tabla usuarios en el cluster, con un ciclo for se le indica la cantidad de usuarios a insertar, los datos solo datos palabras quemadas con vareacon en los numeros. Se utiliza una lista para poder usarla en la la insersion de reservas, para poder asignarle un usuario a la reserva. 
   ```python
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
   ```
- Insertar espacios:
    Esta funcion tiene el mismo funcionamiento que la tabla anterior, prepara un query para insertar datos en la tabla espacios, con un ciclo for se insertar la cantidad de datos necesaria y se almacen en una lista para que al momento de insertar reserva se tenga acceso a espacios. 
  ```python
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
  ```
- Check Overlap: Lo que realiza esta funcon es verificar que no haya solapamiento de informacion, insertar reservas que ya estan ocupadas por otra reserva en esa fecha especifica.
- Insertar Reservas: En esta funcion se prepararon querys para cada una de las tablas creadas para la reservas de espacios, se pasan los palametros que utilizara cada una de las funciones y se hace uso de **BatchStatement** para definir el consistency level que se utilizar para insertar los datos. 
  ```python
   batch = BatchStatement(consistency_level=ConsistencyLevel.QUORUM)
    batch.add(insert_space, params_space)
    batch.add(insert_user, params_user)
    batch.add(insert_date, params_date)
    batch.add(insert_availability, params_availability)

    try:
        session.execute(batch)
        return True
    except Exception as e:
        print(f"Error en BATCH: {e}")
        return False
  ```
## CONSULTAS

### Disponibilidad de un espacio en una fecha
- Para realizar esta consulta se utiliza la materialized view llamada **Consultar disponibilidad de un espacio en una fecha.** 
    ```sql
        SELECT id_espacio, fecha, hora_inicio, hora_fin, estado FROM disponibilidad_espacio  WHERE id_espacio = 9ae1bf97-c8bf-4ce4-aae2-ea539162beb2 AND fecha = '2025-10-16';
    ```
- Para ver historial de reservas de un usuario se utiliza la tabla llamada **reservas_por_usuario** a esta tabla utiliza como llave de particion el anio y el mes para poder mantener el rendimiento en las consultas, ya que si un usuario tiene miles de reservas cargarlas todas de golpe perjudicaria el rendimiento. 
  ```sql
    SELECT id_usuario, fecha,  id_reserva, id_espacio, nombre_reserva, hora_fin, estado  FROM reservas_por_usuario  WHERE id_usuario = cc777809-f610-4b75-b6f3-7b3ffe330a5b    AND fecha_mes = '2025-10' ORDER BY fecha DESC;
  ```

- Para ver Obtener ocupación de espacios en un rango de fechas. Se utilizo la tabla **reservas_por_fecha** 
  ```sql
    SELECT fecha, id_espacio, COUNT(*) AS total_reservas FROM proyecto_1.reservas_por_fecha WHERE fecha >= '2025-10-01'   AND fecha <= '2025-10-31'   AND id_espacio = 50c13cdb-a1ce-4e0f-ae7e-919ead0ba76a allow filtering;
  ```
