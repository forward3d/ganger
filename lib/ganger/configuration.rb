module Ganger
  class Configuration
        
    attr_accessor :docker_daemons, :docker_image, :docker_cmd, :docker_args, :docker_expose
    attr_accessor :proxy_listen_port, :service_timeout, :service_retry
    
    def initialize
      @docker_daemons = ['unix:///var/run/docker.sock']
    end
    
    def docker_cmd_and_args
      [@docker_cmd] + @docker_args
    end
    
    def inspect
      to_s
    end
    
    def to_s
      {
        docker_daemons: @docker_daemons,
        docker_image: @docker_image,
        docker_cmd: @docker_cmd,
        docker_args: @docker_args,
        docker_expose: @docker_expose,
        proxy_listen_port: @proxy_listen_port
      }.inspect
    end
    
  end
end