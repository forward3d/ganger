require 'socket'
require 'yaml'
require 'logger'
require 'uri'
require 'thread'
require 'thread_safe'
require 'docker'
require 'httparty'
require 'json'

require_relative 'ganger/logging'
require_relative 'ganger/engines/static'
require_relative 'ganger/engines/consul'
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
  end
  
  def conf
    @configuration
  end
  
  class MaxContainersReached < StandardError ; end
  class RetryExceeded < StandardError ; end
  class ClientConnectionClosed < StandardError ; end
  
end