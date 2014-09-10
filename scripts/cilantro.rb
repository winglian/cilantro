class Cilantro
    def Cilantro.configureProxy(config, settings)
        config.vm.define "default" do |docker|
            docker.vm.box = "dduportal/boot2docker"
            docker.vm.provider :virtualbox do |vb|
                vb.name = "dockerhost"
            end

            if !settings['ip'].nil?
                docker.vm.network :private_network, ip: settings["ip"], netmask: settings["netmask"] ||= nil
            end

            docker.vbguest.auto_update = false
            
            docker.vm.synced_folder ".", "/vagrant", disabled: true
            settings["folders"].each do |folder|
                docker.vm.synced_folder folder["map"], "/vagrant" + folder["to"], mount_options: folder["mount_options"] ||= ["dmode=775,fmode=664"]
            end
            docker.vm.synced_folder "./srv", "/srv/docker"
            docker.vm.synced_folder "./build", "/vagrant/build"
            docker.vm.synced_folder "./etc", "/vagrant/etc"
            docker.vm.synced_folder "./usr", "/vagrant/usr"

            docker.vm.provision :shell do |s|
                s.inline = <<-EOT
                    sudo /usr/local/bin/ntpclient -s -h pool.ntp.org
                    sudo killall -9 ntpd
                    sudo ntpd -p pool.ntp.org
                    date
                EOT
            end
        end
    end

    def Cilantro.regenerateAuthorizedKeys(settings)
        target = open('usr/share/authorized_keys', 'w')
        target.truncate(0)
        settings['ssh']['public'].each do |key|
            if File.file?(File.expand_path(key['key']))
                key_string = File.readlines File.expand_path(key['key']);
                target.write(key_string[0])
            else
                key_string = key['key']
                target.write(key_string)
                target.write("\n")
            end
        end
        target.close
    end

    def Cilantro.configureContainers(config, settings)
        # allow us to manage the docker host
        if (ARGV[0] == 'status' || ARGV[0] == 'provision' || ARGV[0] == 'reload' ||  ARGV[0] == 'ssh')
            self.configureProxy(config, settings)
        end

        if (ARGV[0] == 'up' || ARGV[0] == 'provision' || ARGV[0] == 'reload')
            self.regenerateAuthorizedKeys(settings)
        end

        settings["services"].each do |service|
            if service['name'] == 'mysql'
                self.configureMysql(config, settings, service)
            elsif service['name'] == 'memcache'
                self.configureMemcache(config, settings)
            elsif service['name'] == 'mongo'
                self.configureMongo(config, settings)
            elsif service['name'] == 'redis'
                self.configureRedis(config, settings)
            elsif service['name'] == 'postgres'
                self.configurePostgres(config, settings)
            elsif service['name'] == 'gearman'
                self.configureGearman(config, settings, service)
            elsif service['name'] == 'web'
                self.configureWeb(config, settings, service)
            elsif service['name'] == 'varnish'
                self.configureVarnish(config, settings, service)
            end
        end
    end

    def Cilantro.configureMysql(config, settings, options)
        # Configure the Mysql Box
        config.vm.define "mysql" do |mysql|
            mysql.vm.provider "docker" do |d|
                d.image = 'mysql:5.6.20'
                d.name = 'mysql'
                d.ports = ['3306:3306']
                d.env    = {
                    'MYSQL_ROOT_PASSWORD' => settings["mysql"]["password"] ||= "secret"
                }
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                # d.volumes = ["/srv/docker/mysql:/var/lib/mysql"]
            end
            mysql.vm.synced_folder ".", "/vagrant", disabled: true
        end
    end
        
    def Cilantro.configureMemcache(config, settings)
        # Configure the Memcached Box
        config.vm.define "memcached" do |memcached|
            memcached.vm.provider "docker" do |d|
                d.image = 'sylvainlasnier/memcached'
                d.name = 'memcache'
                d.ports = ['11211:11211']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
            end
            memcached.vm.synced_folder ".", "/vagrant", disabled: true
        end
    end

    def Cilantro.configureMongo(config, settings)
        config.vm.define "mongo" do |mongo|
            mongo.vm.provider "docker" do |d|
                d.image = 'mongo:2.7.5'
                d.name = 'web_mongo'
                d.ports = ['27017:27017']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                # d.volumes = ["/srv/docker/mongo:/data/db"]
            end
            mongo.vm.synced_folder ".", "/vagrant", disabled: true
        end
    end
        
    def Cilantro.configureRedis(config, settings)
        config.vm.define "redis" do |redis|
            redis.vm.provider "docker" do |d|
                d.image = 'redis'
                d.name = 'web_redis'
                d.ports = ['6379:6379']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                # d.volumes = ["/srv/docker/redis:/data"]
            end
            redis.vm.synced_folder ".", "/vagrant", disabled: true
        end
    end
        
    def Cilantro.configurePostgres(config, settings)
        config.vm.define "postgres" do |postgres|
            postgres.vm.provider "docker" do |d|
                d.image = 'postgres:9.4'
                d.name = 'web_postgres'
                d.ports = ['5432:5432']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                # d.volumes = ["/srv/docker/postgres:/var/lib/postgresql/data"]
            end
            postgres.vm.synced_folder ".", "/vagrant", disabled: true
        end
    end

    def Cilantro.configureGearman(config, settings, options)
        config.vm.define "gearman" do |gearman|
            gearman.vm.provider "docker" do |d|
                d.image = 'licoricelabs/cilantro-gearman:0.0.1'
                d.name = 'gearman'
                d.ports = options['ports'] ||= ['4730:4730']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                d.has_ssh = true
                d.volumes = ["/vagrant/etc:/docker/etc", "/vagrant/usr:/docker/usr"]
                d.env = {
                    "GEARMAND_PORT"         => 4730
                }
            end
            
            gearman.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"
            gearman.ssh.username = 'root'
            gearman.vm.boot_timeout = 10
        end
    end

    def Cilantro.configureVarnish(config, settings, options)
        config.vm.define "varnish" do |varnish|
            varnish.vm.provider "docker" do |d|
                d.image = 'licoricelabs/cilantro-varnish:0.0.2'
                d.name = 'varnish'
                d.ports = options['ports'] ||= ['80:80']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                d.has_ssh = true
                d.volumes = ["/vagrant/etc:/docker/etc", "/vagrant/usr:/docker/usr"]
                vcl = '/etc/varnish/default.vcl';
                if options.has_key?("vcl")
                    vcl = '/docker/' + options["vcl"]
                end
                d.env = {
                    "VARNISH_BACKEND_HOST" => 'web',
                    "VARNISH_BACKEND_PORT" => 80,
                    "VARNISH_PORT"         => 80
                }
                d.link('web:web');
            end
            
            # TODO setup SSH keys
            varnish.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"
            varnish.ssh.username = 'root'
            varnish.vm.boot_timeout = 10
        end
    end

    def Cilantro.configureWeb(config, settings, options)
        config.vm.define "web" do |web|
            web.vm.provider "docker" do |d|
                d.image = 'licoricelabs/cilantro-php:0.0.3'
                d.name = 'web'
                d.ports = options['ports'] ||= ['80:80']
                d.vagrant_vagrantfile = "Vagrantfile.proxy"
                d.has_ssh = true
                d.volumes = ["/vagrant/etc:/docker/etc", "/vagrant/usr:/docker/usr"]
                settings["folders"].each do |folder|
                    d.volumes << "/vagrant" + folder["to"] + ":" + folder["to"]
                end

                # TODO php-fpm pool per site
                
                # map environment variables
                d.env = {};
                if settings.has_key?("variables")
                    settings["variables"].each do |var|
                        d.env[var["key"]] = var["value"]
                    end
                end

                # TODO dynamic mapping
                services = settings["services"].group_by { |s| s["name"] }
                puts services;
                if services.has_key?("mysql")
                    d.link('mysql:' + services["mysql"][0]["alias"]);
                end
                if services.has_key?("memcache")
                    d.link('memcache:' + services["memcache"][0]["alias"]);
                end
                if services.has_key?("gearman")
                    d.link('gearman:' + services["gearman"][0]["alias"]);
                end
            end

            web.vm.boot_timeout = 10

            # TODO setup SSH keys
            web.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"
            web.ssh.username = 'root'

            web.vm.synced_folder ".", "/vagrant", disabled: true
            web.vm.synced_folder "scripts", "/vagrant/scripts"

            # The www-data user should map to the docker UID so that synced folders play nicely
            web.vm.provision "shell", inline:
                "userdel www-data && useradd -d /var/www -s /usr/sbin/nologin -G staff www-data -u 1000"

            pools = {}

            settings["pools"].each do |pool|
                web.vm.provision "shell" do |s|
                    file = pool["file"] ||= "/docker/etc/php5/fpm/template.conf"
                    user = pool["user"] ||= 'www-data'
                    group = pool["group"] ||= 'www-data'
                    s.inline = "cat $5 | sed -e \"s@\\\${pool}@$1@\" -e \"s@\\\${user}@$2@\" -e \"s@\\\${group}@$3@\" -e \"s@\\\${socket}@$4@\" | tee /etc/php5/fpm/pool.d/$1.conf"
                    s.args = [pool["name"], user, group, pool["listen"], file]
                    pools[pool["name"]] = {}
                    pools[pool["name"]]["socket"] = pool["listen"]
                end
            end


            # Configure All Of The Server Environment Variables
            if settings.has_key?("variables")
              settings["variables"].each do |var|
                pool = var["pool"] ||= 'www'
                web.vm.provision "shell" do |s|
                    s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php5/fpm/pool.d/$3.conf"
                    s.args = [var["key"], var["value"], pool]
                end
              end
            end

            settings["sites"].each do |site|
                web.vm.provision "shell" do |s|
                    config = site["ngx_config"] ||= "/docker/etc/nginx/default.conf"
                    pool = site["pool"] ||= "www"
                    s.inline = "cat $4 | sed -e \"s@\\\${server_name}@$1@\" -e \"s@\\\${root}@$2@\" -e \"s@\\\${socket}@$3@\" | tee /etc/nginx/sites-available/$1 && \
                    ln -fs /etc/nginx/sites-available/$1 /etc/nginx/sites-enabled/$1"
                    s.args = [site["map"], site["to"], pools[pool]["socket"], config]
                end
            end

            web.vm.provision "shell" do |s|
                s.inline = "service php5-fpm restart && service nginx restart"
            end

        end
    end
end
