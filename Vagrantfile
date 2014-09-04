VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_NO_PARALLEL'] = "1"
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'docker'

path = "#{File.dirname(__FILE__)}"

require 'yaml'
require path + '/scripts/cilantro.rb'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    Cilantro.configureContainers(config, YAML::load(File.read(path + '/Cilantro.yaml')))
end
