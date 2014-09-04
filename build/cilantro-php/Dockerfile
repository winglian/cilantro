FROM ubuntu:trusty

RUN export LC_ALL=C && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y --force-yes dist-upgrade && \
    apt-get install -y --force-yes software-properties-common && \
    apt-add-repository ppa:nginx/stable -y && \
    apt-add-repository ppa:ondrej/php5 -y && \
    apt-get update && \
    apt-get install -y  --force-yes build-essential curl dos2unix gcc git libmcrypt4 libpcre3-dev make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim php5-cli php5-dev php-pear php5-mysqlnd php5-pgsql php5-sqlite php5-apcu php5-json php5-curl php5-gd php5-gmp php5-imap php5-mcrypt php5-xdebug php5-memcached php5-redis nginx php5-fpm openssh-server libgearman-dev && \
    cd / && \
    rm -rf /var/cache/apt/archives/*.deb /var/lib/apt/lists/* /root/* && \
    apt-get clean
    
RUN pecl install mailparse && \
    echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    printf "\n" | pecl install memcache && echo "extension=memcache.so" | tee /etc/php5/mods-available/memcache.ini && \
    pecl install gearman  && echo "extension=gearman.so" | tee /etc/php5/mods-available/gearman.ini

RUN sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini && \
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini && \
    sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini && \
    sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini && \
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini && \
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/fpm/php.ini && \
    sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/fpm/php.ini && \
    sed -i "s/user www-data;/user www-data www-data;/" /etc/nginx/nginx.conf && \
    sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf && \
    sed -i "s/;listen\.owner.*/listen.owner = www-data/" /etc/php5/fpm/pool.d/www.conf && \
    sed -i "s/;listen\.group.*/listen.group = www-data/" /etc/php5/fpm/pool.d/www.conf && \
    sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php5/fpm/pool.d/www.conf && \
    ln -s /etc/php5/mods-available/mailparse.ini /etc/php5/cli/conf.d/20-mailparse.ini && \
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime && \
    sudo php5enmod mcrypt && \
    sudo php5enmod memcache && \
    sudo php5enmod gearman && \
    rm /etc/nginx/sites-enabled/default && \
    rm /etc/nginx/sites-available/default

RUN mkdir /root/.ssh && \
    chmod 0700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    sed -i "s/PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config && \
    update-rc.d ssh defaults

RUN userdel www-data && \
    useradd -d /var/www -s /usr/sbin/nologin -G staff www-data -u 1000

EXPOSE 80 22 9000
ADD configure.sh /root/configure.sh
ADD entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

