require 'eventmachine'
require 'logger'

module Ganger
  class Proxy
    
    # Receive a connection from a client, ask for a Docker container to service the
    # request, then proxy the connection to the container. When the connection ends,
    # get rid of the container.
    
    def initialize(client_socket)
      @client_socket = client_socket
      @log = Logger.new(STDOUT)
      info "Received connection from #{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}"
      @docker_container = DockerDispatcher.get_docker_container
      info "Obtained a Docker container; service port: #{@docker_container.service_port}"
      @docker_socket = TCPSocket.new(@docker_container.service_host, @docker_container.service_port)
    end
    
    def main_loop
      begin
        proxy
      rescue StandardError => e
        fatal "Exception: #{e.message}"
        fatal e.backtrace.join("\n")
        cleanup
      end
    end
    
    def proxy
      info "Entering proxy loop"
      loop do
        (ready_sockets, dummy, dummy) = IO.select([@client_socket, @docker_socket])
        begin
          ready_sockets.each do |socket|
            data = socket.readpartial(4096)
            if socket == @client_socket
              @docker_socket.write(data)
              @docker_socket.flush
            else
              @client_socket.write(data)
              @client_socket.flush
            end
          end
        rescue EOFError
          info "Closing connection"
          break
        end
      end
      cleanup
    end
    
    def cleanup
      info "Cleaning up"
      @docker_container.dispose
      @client_socket.close
      @docker_socket.close
    end
    
    private
    
    def info(msg)
      @log.info "#{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}: #{msg}"
    end
    
    def fatal(msg)
      @log.info "#{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}: #{msg}"
    end
    
  end
end