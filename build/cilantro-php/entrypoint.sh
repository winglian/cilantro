#!/usr/bin/env bash

/root/configure.sh

service ssh start
service nginx start

tail -f /dev/null

