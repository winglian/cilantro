FROM ubuntu:trusty

RUN export LC_ALL=C && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y --force-yes dist-upgrade && \
    apt-get install -y --force-yes gearman openssh-server && \
    cd / && \
    rm -rf /var/cache/apt/archives/*.deb /var/lib/apt/lists/* /root/* && \
    apt-get clean

EXPOSE 4730

ENV GEARMAND_PORT 4730

ADD configure.sh /root/configure.sh
ADD start.sh /root/start.sh
ENTRYPOINT ["/root/start.sh"]
