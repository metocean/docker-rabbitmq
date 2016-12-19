#!/bin/bash

trap 'consul leave && kill -TERM $PID' TERM INT
if [ -z "$CONSULDATA" ]; then export CONSULDATA="/tmp/consul-data";fi
if [ -z "$CONSULDIR" ]; then export CONSULDIR="/consul";fi


if [ "$(ls -A $CONSULDIR)" ]; then
    cat <<EOF >> /consul/rabbit.json
{
  "service": {
    "name": "${RABBITMQ_CLUSTER_MEMBER:-rabbit1}",
    "port": 5672,
    "terminate_on_leave": true,
    "checks": [{"script": "rabbitmqctl status",
                "interval": "10s"}]
  }
}
EOF
    consul agent -data-dir=$CONSULDATA -config-dir=$CONSULDIR &
    sleep 3
fi

if [ -n "$RABBITMQ_JOIN_CLUSTER" ]; then
    for rabbit in $(echo $RABBITMQ_JOIN_CLUSTER | tr "," "\n"); do
        RABBITIP=`dig $rabbit.service.consul +short`
        if [ -n "$RABBITIP" ]; then
            echo "$RABBITIP $rabbit $rabbit.service.consul" >> /etc/hosts;
            export RABBIT_TO_JOIN=$rabbit
        fi
    done
fi

chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie

rabbitmq-server -detached

if [ -n "$RABBITMQ_JOIN_CLUSTER" ] && [ -n "$RABBIT_TO_JOIN" ]; then
    echo "Cluster members found, will try to join cluster!"
    rabbitmqctl stop_app
    rabbitmqctl join_cluster rabbit@$RABBIT_TO_JOIN
    rabbitmqctl start_app
    rabbitmqctl cluster_status
fi

PID=$!
wait $PID
trap - TERM INT
wait $PID