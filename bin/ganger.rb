#!/usr/bin/env ruby

require 'bundler'
Bundler.setup
require_relative '../lib/ganger'

# Logging
$stdout.sync = true
@log = Logger.new(STDOUT)

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
@log.info("Using config file: #{CONFIG_FILE}")
Ganger.configure do |configuration|
  Ganger::YamlConfigLoader.load_from_file(configuration, CONFIG_FILE)
end
@log.info("Loaded configuration from YAML file: #{Ganger.configuration}")

# Start the service
server = TCPServer.new(nil, Ganger.configuration.proxy_listen_port)
loop do
  @threads << Thread.new(server.accept) do |client_socket|
    proxy = Ganger::Proxy.new(client_socket)
    proxy.main_loop
  end
end