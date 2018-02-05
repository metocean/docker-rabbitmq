#!/bin/bash

trap 'consul leave && kill -TERM $PID' TERM INT
if [ -z "$CONSULDATA" ]; then export CONSULDATA="/tmp/consul-data";fi
if [ -z "$CONSULDIR" ]; then export CONSULDIR="/consul";fi

export RABBITMQ_CLUSTER_MEMBER=${RABBITMQ_CLUSTER_MEMBER:-`hostname`}
export RABBITMQ_CONSUL_SERVICE=${RABBITMQ_CONSUL_SERVICE:-rabbitmq}

if [ -n "$(ls -A $CONSULDIR)" ]; then
    if [ ! -f "$CONSULDIR/rabbit.json" ]; then
        cat <<EOF >> /consul/rabbit.json
{
  "service": {
    "name": "$RABBITMQ_CONSUL_SERVICE",
    "tags" : ["$RABBITMQ_CLUSTER_MEMBER","`hostname`"],
    "port": 5672,
    "checks": [{"script": "rabbitmqctl status",
                "interval": "10s"}]
  }
}
EOF
fi
    cat /consul/rabbit.json
    consul agent -data-dir=$CONSULDATA -config-dir=$CONSULDIR &
    sleep 3
    if [ -z "$RABBITMQ_JOIN_CLUSTER" ]; then        
        RABBITMQ_JOIN_CLUSTER=`consul catalog services -tags | grep $RABBITMQ_CONSUL_SERVICE | sed -E "s/$RABBITMQ_CONSUL_SERVICE\s+//g"`
    fi
    RABBITS_TO_JOIN=
    for rabbit in $(echo $RABBITMQ_JOIN_CLUSTER | tr "," "\n"); do
        RABBITIP=`dig @127.0.0.1 +time=1 +tries=3 $rabbit.$RABBITMQ_CONSUL_SERVICE.service.consul +short`
        if [ ! "$rabbit" = "$RABBITMQ_CLUSTER_MEMBER" -a -n "$RABBITIP" ]; then
            echo "$RABBITIP $rabbit $rabbit.$RABBITMQ_CONSUL_SERVICE.service.consul" >> /etc/hosts;
            export RABBITS_TO_JOIN+=rabbit@$rabbit,
        fi
    done
    RABBITS_TO_JOIN=`echo $RABBITS_TO_JOIN | sed 's/,$//g'`
    echo $RABBITMQ_JOIN_CLUSTER $RABBITS_TO_JOIN

fi

chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie

rabbitmq-server -detached
PID=$!

if [ -n "$RABBITS_TO_JOIN" ]; then
    echo "Cluster members found, will try to join cluster!"
    rabbitmqctl stop_app
    rabbitmqctl join_cluster $RABBITS_TO_JOIN
    rabbitmqctl start_app
    rabbitmqctl cluster_status
fi

wait $PID
trap - TERM INT
wait $PID