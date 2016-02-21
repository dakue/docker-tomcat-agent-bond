#!/bin/bash
set -e

VERSIONS="8-jre7 8-jre8"
NAME="Tomcat"
NAME_PORT="8080"
DOCKER_IMAGE_BASE="dakue/tomcat-agent-bond"

echo "$(date --iso-8601=seconds) INFO: starting to test"
for VERSION in $VERSIONS
do
    VERSION_NAME="es-$(echo $VERSION | sed 's|\.|-|g')"
    echo "INFO: starting $NAME version $VERSION"
    docker run -d -p $NAME_PORT:$NAME_PORT -p 8778:8778 -p 9779:9779 --name $VERSION_NAME $DOCKER_IMAGE_BASE:$VERSION
    echo "INFO: waiting for $NAME to be available"
    ( i=0; until nc -w 1 -q 0 localhost $NAME_PORT; do echo $i; test $i -ge 5 && break; sleep 5; ((i++)); done ) || exit 0
    echo "INFO: $VERSION $NAME output"
    curl -sS http://localhost:$NAME_PORT
    echo "INFO: $VERSION Jolokia output"
    curl -sS http://localhost:8778/jolokia/version
    echo "INFO: $VERSION JMX exporter output"
    curl -sS http://localhost:9779/metrics | grep -v -E "HELP|TYPE"
    echo "INFO: stopping $NAME version $VERSION"
    docker stop $VERSION_NAME
done
echo "$(date --iso-8601=seconds) INFO: tests finished"
touch .passed
