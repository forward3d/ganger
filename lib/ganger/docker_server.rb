require 'docker'

module Ganger
  class DockerServer
    
    def initialize(docker_url)
      @docker_url = docker_url
      @connection = Docker::Connection.new(docker_url, {})
      @containers = []
      @image_pulled = false
    end

    def launch_container
      loop do 
        container = create_container
        if container.service_port.nil?
          warn "Got a broken container; disposing and recreating"
          container.dispose
          sleep 5
        else
          @containers << container
          return container
        end
      end
    end
    
    def create_container
      pull_image unless @image_pulled
      container_opts = {
        'Image' => Ganger.configuration.docker_image,
        'ExposedPorts' => { Ganger.configuration.docker_expose => {} }
      }
      container_opts['Cmd'] = Ganger.configuration.docker_cmd if Ganger.configuration.docker_cmd

      container = Docker::Container.create(container_opts, @connection)
      container.start({
        "PortBindings" => { 
          Ganger.configuration.docker_expose => [{"HostPort" => ""}]
        }
      })
      DockerContainer.new(container, @docker_url)
    end
    
    def kill_containers
      @containers.each do |container|
        container.dispose
      end
    end
    
    def container_count
      @containers.size
    end
    
    def pull_image
      Docker::Image.create({'fromImage' => Ganger.configuration.docker_image}, nil, @connection)
      @image_pulled = true
    end
    
  end
end