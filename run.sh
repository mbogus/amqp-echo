#!/usr/bin/env bash

set -e

if [ -n "$KUBERNETES_RABBITMQ_SERVICE_NAME" ]; then
    RABBITMQ_HOST_VAR=${KUBERNETES_RABBITMQ_SERVICE_NAME}_SERVICE_HOST
    RABBITMQ_HOST=${!RABBITMQ_HOST_VAR}
fi

if [ -z "$RABBITMQ_URI" ]; then
    RABBITMQ_PROTO=${RABBITMQ_PROTO:-amqp}
    RABBITMQ_USER=${RABBITMQ_USER:-guest}
    RABBITMQ_PASS=${RABBITMQ_PASS:-guest}
    RABBITMQ_HOST=${RABBITMQ_HOST:-127.0.0.1}
    RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
    RABBITMQ_VHOST=${RABBITMQ_VHOST:-/}
    RABBITMQ_URI=${RABBITMQ_PROTO}://${RABBITMQ_USER}:${RABBITMQ_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}/${RABBITMQ_VHOST}
fi

if [ -n "$RABBITMQ_URI" ]; then
    PRG_ARGS="${PRG_ARGS} --uri='${RABBITMQ_URI}'"
fi

if [ -n "$RABBITMQ_QUEUE" ]; then
    PRG_ARGS="${PRG_ARGS} --queue=${RABBITMQ_QUEUE}"
fi

if [ -n "$ECHO_DELAY" ]; then
    PRG_ARGS="${PRG_ARGS} --delay=${ECHO_DELAY}"
fi

_term() {
  echo "Received SIGTERM signal"
  kill -TERM "$GO_PID" 2>/dev/null
}

trap _term SIGTERM

eval "./amqp-echo ${PRG_ARGS} 2>&1" &

GO_PID=$!
wait "$GO_PID"
