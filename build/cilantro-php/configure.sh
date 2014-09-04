#!/usr/bin/env bash

mkdir -p /root/.ssh
chmod 0700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
sed -i "s/PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config

if [ -f /docker/usr/share/authorized_keys ]; then
    cat /docker/usr/share/authorized_keys > /root/.ssh/authorized_keys
fi
