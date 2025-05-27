# Practica 1 - Transacciones

En esta Practica se trabajo con **SQL SERVER**. Trata sobre el sistema de bases de datos de una Universidad donde el objetivo de la practica era aprender a trabajar con **TRANSACCIONES**  y sus propiedades **ACID**. Se implementaron procedimientos  almacenados para Registrar,  Actualizar, Crear Relaciones (cursos con alumnos), Creacion de recursos y Validacion de datos. Tambien se crearon Funciones para obtener Informacion del sisteme como el codigo de un curso, tutor de un curso, funciones para notificar a un usuario por correo.

# Proyecto 1 - Bases de datos Distribuidas

Este proyecto trata sobre un negocio de reservas de espacios compartidos en un sistemas de coworking o renta de salas de conferencia.

Este proyecto se desarrollo Utilizando **Apache Cassandra**, implementando un cluster con 3 nodos, los cuales fueron levantados y comunicados por **docker compose**. Se le configuro Replication Factor y Consistency Leves para obtener mayor **Disponibilidad y Rendimiento**.

Se diseno el modelo conceptual, Logico y fisico para este sistema, configurando de la forma mas eficiente las claves de particion, llaves primarias compuestas y las claves de clustering, para evitar el uso de **ALLOW FILTERING** En las consultas mas frecuentes.

Dado que la finalidad del proyecto era verificar los tiempos de consulta  (se utilizo Consistency Levels **ONE**, **QOURUM** Y **ALL**) de la base de datos se creo un Scrip en python para la carga masiva de todos los datos utilizando **Batch Writes**. 
