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
CONFIG_FILE = File.expand_path("../../config/ganger-config.rb", __FILE__)
config_file = ARGV.empty? ? CONFIG_FILE : File.expand_path(ARGV.first)

log.info("Using config file: #{config_file}")
require config_file

log.info("Loaded configuration from file: #{Ganger.conf.to_s}")

# Set Excon timeouts so API requests don't time out
Excon.defaults[:write_timeout] = Ganger.conf.ganger.docker_timeout
Excon.defaults[:read_timeout] = Ganger.conf.ganger.docker_timeout

# Preload image by telling each Docker server configured to fetch it
log.info("Telling all configured Docker servers to pull the image: #{Ganger.conf.docker.image}")
Ganger::DockerDispatcher.preload_image

# Start the service
log.info("Starting TCP server on #{Ganger.conf.ganger.listen_port}")
server = TCPServer.new(nil, Ganger.conf.ganger.listen_port)
loop do
  @threads << Thread.new(server.accept) do |client_socket|
    proxy = Ganger::Proxy.new(client_socket)
    proxy.main_loop
  end
end