module Ganger
  class ConnectionDispatcher
    extend Logging
    
    # Poll the connection queue (which is full of accepted socket
    # connections). When we get a socket, see if we can get a Docker container to
    # service it. If we can't, we're at max capacity, so sleep a bit and then
    # retry.
    
    def self.docker_manager=(docker_manager)
      @docker_manager = docker_manager
    end
    
    def self.run
      info "Starting ConnectionDispatcher thread"
      @connection_queue = Queue.new
      @threads = []
      loop do
        begin
          info "Polling connection queue for connections"
          socket = @connection_queue.pop
          
          # This call will block until a container can be returned
          info "Received connection, polling for a Docker container"
          container = @docker_manager.get_container
          
          info "Container obtained, launching a proxy thread"
          @threads << Thread.new(socket, container, @docker_manager) do |socket, container, docker_manager|
            begin
              Proxy.new(socket, container).proxy
            ensure
              docker_manager.dispose_of_container(container)
              socket.close
            end
            info "Proxying completed; exiting proxy thread"
          end
        rescue => e
          fatal "An error occurred while proxying: #{e.class}: #{e.message}"
          fatal e.backtrace
        end
      end
    end
    
    def self.push(socket)
      @connection_queue.push(socket)
    end
    
  end
end