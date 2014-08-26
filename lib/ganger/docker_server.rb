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
      internal_container = DockerContainer.new(container, @docker_url)
      @containers << internal_container
      internal_container
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
      Docker::Image.create({'fromImage' => Ganger.configuration.docker_image}, @connection)
      @image_pulled = true
    end
    
  end
end