#!/usr/bin/env bash

/root/configure.sh

service ssh start

varnishd -f /etc/varnish/default.vcl -s malloc,100M -a 0.0.0.0:${VARNISH_PORT}

varnishlog
