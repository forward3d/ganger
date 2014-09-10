require 'socket'
require 'yaml'
require 'logger'
require 'uri'

require_relative 'ganger/yaml_config_loader'
require_relative 'ganger/docker_server'
require_relative 'ganger/docker_container'
require_relative 'ganger/docker_dispatcher'
require_relative 'ganger/configuration'
require_relative 'ganger/proxy'

module Ganger
  extend self
  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new
    yield configuration
    configuration.docker.daemons = [configuration.docker.daemons] unless configuration.docker.daemons.is_a? Array
    configuration.docker.daemons.map! do |daemon_address|
      daemon_address == 'boot2docker' ? find_boot2docker_ip : daemon_address
    end
  end
  
  def conf
    @configuration
  end
  
  def find_boot2docker_ip
    output = `/usr/local/bin/boot2docker ip 2>/dev/null`
    if $?.exitstatus != 0
      raise "boot2docker was specified as one of the docker daemons, but it could not be run!"
    end
    "tcp://#{output}:2375"
  end
  
  class MaxContainersReached < Exception ; end
  
end