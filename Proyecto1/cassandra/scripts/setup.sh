#!/bin/bash

# Configuración dinámica basada en variables de entorno
echo "endpoint_snitch: ${CASSANDRA_ENDPOINT_SNITCH}" >> /etc/cassandra/cassandra.yaml

echo "auto_bootstrap: ${CASSANDRA_AUTO_BOOTSTRAP:-true}" >> /etc/cassandra/cassandra.yaml

sed -i "s/^cluster_name:.*/cluster_name: '${CASSANDRA_CLUSTER_NAME}'/" /etc/cassandra/cassandra.yaml
sed -i "s/^seeds:.*/seeds: \"${CASSANDRA_SEEDS}\"/" /etc/cassandra/cassandra.yaml




# Iniciar Cassandra
exec docker-entrypoint.sh "$@"