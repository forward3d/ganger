require 'socket'
require 'yaml'
require 'logger'
require 'uri'
require 'thread'
require 'thread_safe'
require 'docker'

require_relative 'ganger/logging'
require_relative 'ganger/engines/static'
require_relative 'ganger/docker_manager'
require_relative 'ganger/connection_dispatcher'
require_relative 'ganger/docker_server'
require_relative 'ganger/docker_container'
require_relative 'ganger/configuration'
require_relative 'ganger/proxy'

module Ganger
  extend self
  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new
    yield configuration
    configuration.docker.daemons.map! do |hash|
      hash[:url] == 'boot2docker' ? {url: find_boot2docker_ip, max_containers: hash[:max_containers]} : hash
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