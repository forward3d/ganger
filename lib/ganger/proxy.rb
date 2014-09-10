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
    end
    
    def main_loop
      begin
        obtain_docker_container
        connect_to_service
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
        (ready_sockets, dummy, dummy) = IO.select([@client_socket, @service_socket])
        begin
          ready_sockets.each do |socket|
            data = socket.readpartial(4096)
            if socket == @client_socket
              @service_socket.write(data)
              @service_socket.flush
            else
              @client_socket.write(data)
              @client_socket.flush
            end
          end
        rescue EOFError
          info "Closing connection"
          break
        rescue
          fatal "Encountered exception while proxying: #{e.class}: #{e.message}"
          break
        end
      end
      cleanup
    end
    
    def cleanup
      info "Cleaning up"
      DockerDispatcher.dispose_container(@docker_container)
      @client_socket.close
    end
    
    private

    def get_service_socket           
      addr = Socket.getaddrinfo(@docker_container.service_host, nil)
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      seconds  = Ganger.configuration.service_timeout
      useconds = 0
      sockopt_value = [seconds, useconds].pack("l_2")
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, sockopt_value)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, sockopt_value)
      socket
    end
    
    def connect_to_service
      Ganger.configuration.service_retry.times do |count|
        begin
          socket = get_service_socket
          socket.connect(
            Socket.pack_sockaddr_in(@docker_container.service_port.to_i, @docker_container.service_host)
          )
          @service_socket = socket
          break
        rescue SystemCallError => e
          if count == Ganger.configuration.service_retry
            raise "No connection established with container after #{Ganger.configuration.service_retry} attempts; terminating connection"
          end
          # For timeouts, don't sleep; retry immediately as time has passed
          if e.is_a?(Errno::ETIMEDOUT)
            info "Timeout connecting to service after #{Ganger.configuration.service_timeout} seconds; retrying"
          elsif e.is_a?(Errno::ECONNREFUSED)
            info "Connection refused; retrying in #{Ganger.configuration.service_timeout} seconds"
            sleep Ganger.configuration.service_timeout
          else
            # Other errors should occur relatively quickly - so sleep a bit then retry
            info "Exception thrown during connection to service: #{e.class}; retrying in #{Ganger.configuration.service_timeout} seconds"
            sleep Ganger.configuration.service_timeout
          end
        end
      end
      info "Connection established"
    end
    
    def obtain_docker_container
      loop do
        begin
          @docker_container = DockerDispatcher.get_docker_container
          info "Obtained a Docker container; service port: #{@docker_container.service_port}"
          break
        rescue MaxContainersReached => e
          warn "Max containers reached on target server, sleeping and retrying"
          sleep 5
        end
      end
    end
    
    def info(msg)
      @log.info "#{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}: #{msg}"
    end
    
    def warn(msg)
      @log.info "#{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}: #{msg}"
    end
    
    def fatal(msg)
      @log.info "#{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}: #{msg}"
    end
    
  end
end