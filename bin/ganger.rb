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

# Load configuration
CONFIG_FILE = File.expand_path("../../config/ganger.yaml", __FILE__)
config_file = ARGV.empty? ? CONFIG_FILE : File.expand_path(ARGV.first)

log.info("Using config file: #{config_file}")
Ganger.configure do |configuration|
  Ganger::YamlConfigLoader.load_from_file(configuration, config_file)
end
log.info("Loaded configuration from YAML file: #{Ganger.configuration}")

# Set Excon timeouts so API requests don't time out
Excon.defaults[:write_timeout] = Ganger.configuration.docker_timeout
Excon.defaults[:read_timeout] = Ganger.configuration.docker_timeout

# Preload image by telling each Docker server configured to fetch it
log.info("Telling all configured Docker servers to pull the image: #{Ganger.configuration.docker_image}")
Ganger::DockerDispatcher.preload_image

# Start the service
server = TCPServer.new(nil, Ganger.configuration.proxy_listen_port)
loop do
  @threads << Thread.new(server.accept) do |client_socket|
    proxy = Ganger::Proxy.new(client_socket)
    proxy.main_loop
  end
end