module Ganger
  class Proxy
    include Logging
    
    def initialize(client_socket, container)
      @container = container
      @client_socket = client_socket
      @log = Logger.new(STDOUT)
      info "Received connection from #{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}"
    end
    
    def proxy
      info "Entering proxy loop"
      connect_to_service
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
        end
      end
    end
    
    private

    def get_service_socket           
      addr = Socket.getaddrinfo(@container.service_host, nil)
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      seconds  = Ganger.conf.ganger.service_connection_timeout
      useconds = 0
      sockopt_value = [seconds, useconds].pack("l_2")
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, sockopt_value)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, sockopt_value)
      socket
    end
    
    def connect_to_service
      Ganger.conf.ganger.service_connection_retries.times do |count|
        begin
          socket = get_service_socket
          socket.connect(
            Socket.pack_sockaddr_in(@container.service_port.to_i, @container.service_host)
          )
          @service_socket = socket
          break
        rescue SystemCallError => e
          if count == Ganger.conf.ganger.service_connection_retries
            raise "No connection established with container after #{Ganger.conf.ganger.service_connection_retries} attempts; terminating connection"
          end
          # For timeouts, don't sleep; retry immediately as time has passed
          if e.is_a?(Errno::ETIMEDOUT)
            info "Timeout connecting to service after #{Ganger.conf.ganger.service_connection_timeout} seconds; retrying"
          elsif e.is_a?(Errno::ECONNREFUSED)
            info "Connection refused; retrying in #{Ganger.conf.ganger.service_connection_timeout} seconds"
            sleep Ganger.conf.ganger.service_connection_timeout
          else
            # Other errors should occur relatively quickly - so sleep a bit then retry
            info "Exception thrown during connection to service: #{e.class}; retrying in #{Ganger.conf.ganger.service_connection_timeout} seconds"
            sleep Ganger.conf.ganger.service_connection_timeout
          end
        end
      end
      info "Connection established"
    end
    
  end
end
