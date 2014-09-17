module Ganger
  class Proxy
    include Logging
    
    def initialize(client_socket, container)
      @container = container
      @client_socket = client_socket
      @log = Logger.new(STDOUT)
      info "Received connection from #{@client_socket.remote_address.ip_address}:#{@client_socket.remote_address.ip_port}"
      @current_retry = 0
    end
    
    def proxy
      begin
        connect_service_socket
        loop do
          handle_ready_sockets
        end
      rescue => e
        info "Closing connection: #{e.class}: #{e.message}"
      end
    end
    
    private
    
    def handle_ready_sockets
      (ready_sockets, dummy, dummy) = IO.select([@client_socket, @service_socket])
      ready_sockets.each do |socket|
        if socket == @client_socket
          write_to_server
        else
          write_to_client
        end
      end
    end
    
    def write_to_server
      loop do
        
        # Read from the client
        begin
          # Buffer data in case client write gets connection reset
          @server_send_buffer ||= @client_socket.readpartial(4096)
        rescue EOFError
          # The client hung up their connection
          raise Ganger::ClientConnectionClosed, "Client closed connection while we were reading data from them"
        end
        
        # Write to the server
        begin
          @service_socket.write(@server_send_buffer)
          @service_socket.flush
          break
        rescue EOFError, Errno::ECONNRESET
          # Retry if the connection gets reset
          increment_and_raise_if_retry_exceeded
          info "Connection reset thrown while writing to the server; sleeping and retrying"
          wait_for_timeout
          connect_service_socket
        rescue => e
          # Raise any other kind of exception up to the proxy loop
          raise e
        end
      end
    end
    
    def write_to_client
      
      # Read from the server
      data = nil
      begin
        # If we make it through a read without a connection reset, we know we've 
        # managed to send data to the server
        data = @service_socket.readpartial(4096)
        reset_server_send_buffer
      rescue EOFError, Errno::ECONNRESET
        # We tried to read but got our connection reset - reconnect and send the last data again,
        # then try and read the response again
        info "Connection reset reading response from server; retrying writing previous data in 5 seconds"
        increment_and_raise_if_retry_exceeded
        wait_for_timeout
        connect_service_socket
        write_to_server
      end
      
      # Write to the client
      begin
        @client_socket.write(data)
        @client_socket.flush
      rescue EOFError
        # Client hung up
        raise Ganger::ClientConnectionClosed, "Client closed connection while we were writing data to them"
      end
      
    end
    
    def reset_server_send_buffer
      @server_send_buffer = nil
    end
    
    def increment_retry_count
      @current_retry = @current_retry + 1
    end
    
    def retry_exceeded?
      @current_retry == Ganger.conf.ganger.service_connection_retries - 1
    end
    
    def increment_and_raise_if_retry_exceeded
      increment_retry_count
      info "Retry: #{@current_retry}/#{Ganger.conf.ganger.service_connection_retries}"
      raise Ganger::RetryExceeded, "Retries exceeded while trying to write to the server" if retry_exceeded?
    end
    
    def get_service_socket           
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      seconds  = Ganger.conf.ganger.service_connection_timeout
      useconds = 0
      sockopt_value = [seconds, useconds].pack("l_2")
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, sockopt_value)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, sockopt_value)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @service_socket = socket
    end
    
    def connect_service_socket
      loop do
        begin
          get_service_socket
          @service_socket.connect(
            Socket.pack_sockaddr_in(@container.service_port.to_i, @container.service_host)
          )
          break
        rescue Errno::ETIMEDOUT
          info "Timeout connecting to service after #{Ganger.conf.ganger.service_connection_timeout} seconds; retrying"
        rescue Errno::ECONNREFUSED
          info "Connection refused; retrying in #{Ganger.conf.ganger.service_connection_timeout} seconds"
        rescue
          info "Exception thrown during connection to service: #{e.class}; retrying in #{Ganger.conf.ganger.service_connection_timeout} seconds"
        ensure
          increment_and_raise_if_retry_exceeded
          wait_for_timeout
        end
      end
    end
    
    def wait_for_timeout
      sleep Ganger.conf.ganger.service_connection_timeout
    end
    
  end
end
