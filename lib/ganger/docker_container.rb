module Ganger
  
  class DockerContainer
    
    attr_reader :service_host, :service_port, :id, :docker_url
    
    def initialize(container, docker_url)
      @docker_url = docker_url
      @log = Logger.new(STDOUT)
      @container = container
      @id = @container.json["Id"]
      @name = @container.json["Name"].gsub('/', '')
      info "Created container with properties: #{container.json.to_s}"
      
      # Figure out host and port for the service in this container
      @service_host = URI.parse(docker_url).host
      get_service_port
      
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
    
    def get_service_port
      begin
        @service_port = @container.json["NetworkSettings"]["Ports"][Ganger.configuration.docker_expose].first["HostPort"]
        info "Obtained service port: #{@service_port}"
      rescue
        @service_port = nil
        warn "Container is broken - could not obtain service port"
      end
    end
    
    def info(msg)
      @log.info "#{@name}: #{msg}"
    end
    
    def fatal(msg)
      @log.fatal "#{@name}: #{msg}"
    end
    
  end
  
end