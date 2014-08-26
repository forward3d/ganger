module Ganger
  class Configuration
        
    attr_accessor :docker_daemons, :docker_image, :docker_cmd, :docker_expose
    attr_accessor :proxy_listen_port, :service_timeout, :service_retry
    attr_accessor :docker_timeout
    
    def initialize
      @docker_daemons = ['unix:///var/run/docker.sock']
    end
    
    def inspect
      to_s
    end
    
    def to_s
      {
        docker_daemons: @docker_daemons,
        docker_image: @docker_image,
        docker_cmd: @docker_cmd,
        docker_expose: @docker_expose,
        proxy_listen_port: @proxy_listen_port,
        service_timeout: @service_timeout,
        service_retry: @service_retry,
        docker_timeout: @docker_timeout
      }.inspect
    end
    
  end
end