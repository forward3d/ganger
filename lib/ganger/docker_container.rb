module Ganger
  
  class DockerContainer
    
    attr_accessor :service_host, :service_port
    
    def initialize(container, docker_uri)
      @log = Logger.new(STDOUT)
      @container = container
      @name = @container.json["Name"].gsub('/', '')
      info "Created container with properties: #{container.json.to_s}"
      
      # Figure out host and port for the service in this container
      @service_host = URI.parse(docker_uri).host
      @service_port = @container.json["NetworkSettings"]["Ports"][Ganger.configuration.docker_expose].first["HostPort"]
      
      info "Service host is: #{@service_host}; service port is #{@service_port}"
      
    end
    
    def dispose
      begin
        info "Dispose was called - stopping and removing container"
        @container.kill(:signal => "SIGKILL")
        @container.delete(:force => true)
      rescue => e
        fatal "Disposal of container failed with exception: #{e.class}: #{e.message}"
      end
    end
    
    private
    
    def info(msg)
      @log.info "#{@name}: #{msg}"
    end
    
    def fatal(msg)
      @log.fatal "#{@name}: #{msg}"
    end
    
  end
  
end