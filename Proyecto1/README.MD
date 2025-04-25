# DOCUMENTACION 
## Docker Compose
**Service**
Aqui se definen los contenedores. los contenedores que se van a levantar, para este caso se necesitaran 3 nodos.
1. **cassandra-node1**
build: ./cassandra Le dice a Docker que construya la imagen usando el contexto y el Dockerfile ubicados en la carpeta ./cassandra. Esto permite personalizar la imagen de Cassandra si lo deseas.

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
docker-compose up -d
```
Verificar estado de cluster
```bash
docker exec -it cassandra-node1 nodetool status #Deben estar los 3 levantados

#Si estan los 3 nodos ejecutadonse pasar al siguiente paso
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
    id_reserva TIMEUUID, 
    id_espacio UUID,
    nombre_reserva TEXT,
    hora_fin TIME,      
    estado TEXT,       
    PRIMARY KEY ((id_usuario), fecha, id_reserva)
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



CREATE TABLE proyecto_1.disponibilidad_espacio (
    id_espacio UUID,
    fecha DATE,
    hora_inicio TIMESTAMP,
    hora_fin TIMESTAMP,
    id_reserva UUID,
    estado TEXT,  -- Nuevo campo
    PRIMARY KEY ((id_espacio, fecha), hora_inicio, estado)  -- Incluir estado como clustering key
) WITH CLUSTERING ORDER BY (hora_inicio ASC, estado ASC);

CREATE TABLE proyecto_1.reservas_por_estado (
    estado TEXT,
    id_reserva UUID,
    id_espacio UUID,
    id_usuario UUID,
    fecha DATE,
    hora_inicio TIMESTAMP,
    hora_fin TIMESTAMP,
    PRIMARY KEY ((estado), id_reserva)
) WITH CLUSTERING ORDER BY (id_reserva ASC);
```