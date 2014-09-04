#!/usr/bin/env bash

mkdir -p /root/.ssh
chmod 0700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
sed -i "s/PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config

if [ -f /docker/usr/share/authorized_keys ]; then
    cat /docker/usr/share/authorized_keys > /root/.ssh/authorized_keys
fi

if [ -f /docker/etc/varnish/default.vcl ]; then
    cp /docker/etc/varnish/default.vcl /etc/varnish/default.vcl
fi

# Parse Environment vars in VCL
envs=`printenv`
for env in $envs
do
    IFS== read name value <<< "$env"
    sed -i "s|\${${name}}|${value}|g" /etc/varnish/default.vcl
done

