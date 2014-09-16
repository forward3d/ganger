#!/usr/bin/env ruby

require 'bundler'
Bundler.setup
require_relative '../lib/ganger'

# Logging
$stdout.sync = true
log = Logger.new(STDOUT)

# Keep track of threads, get a stack trace if a thread blows up
@threads = []
Thread.abort_on_exception = true

# Cleanup when interrupted or sent SIGTERM
def cleanup_for_exit
  puts "Exiting..."
  exit 0
end

Signal.trap('SIGINT') do
  cleanup_for_exit
end

Signal.trap('SIGTERM') do
  cleanup_for_exit
end

# Go for environment variable, then supplied file
config_file = ENV['GANGER_CONFIG_FILE'] || ARGV.first
if config_file.nil?
  log.fatal("Failed to load a config file from env var GANGER_CONFIG_FILE and no file supplied as argument; cannot run")
  exit 1
end

log.info("Using config file: #{config_file}")
require config_file
unless Ganger.configuration.valid?
  log.fatal("Configuration invalid; exiting")
  exit 1
end

log.info("Loaded configuration from file: #{Ganger.conf.to_s}")

# Set Excon timeouts so API requests don't time out
Excon.defaults[:write_timeout] = Ganger.conf.ganger.docker_timeout
Excon.defaults[:read_timeout] = Ganger.conf.ganger.docker_timeout

# Choose the Ganger discovery engine
docker_manager = Ganger::DockerManager.new
case Ganger.conf.ganger.docker_discovery
when 'static'
  docker_manager.engine = Ganger::Engines::Static.new
when 'consul'
  docker_manager.engine = Ganger::Engines::Consul.new
end

# Validate the discovery engine has all the options it requires
unless docker_manager.engine.config_valid?
  log.fatal("Engine config is invalid; exiting")
  exit 1
end

# Preload image by telling each Docker server configured to fetch it
log.info("Telling all configured Docker servers to pull the image: #{Ganger.conf.docker.image}")
docker_manager.pull_image

# Start the connection-dispatching thread
Ganger::ConnectionDispatcher.docker_manager = docker_manager
connection_dispatch_thread = Thread.new { Ganger::ConnectionDispatcher.run }

# Start the proxy listening port
log.info("Starting TCP server on #{Ganger.conf.ganger.listen_port}")
server = TCPServer.new(nil, Ganger.conf.ganger.listen_port)
loop do
  Ganger::ConnectionDispatcher.push(server.accept)
end