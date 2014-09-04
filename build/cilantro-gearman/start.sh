#!/usr/bin/env bash

/root/configure.sh

service ssh start

gearmand -L0.0.0.0 -p ${GEARMAND_PORT} -d

tail -f /dev/null
