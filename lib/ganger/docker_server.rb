require 'docker'
require 'thread'

module Ganger
  class DockerServer
    
    attr_reader :docker_url
    
    def initialize(docker_url)
      @docker_url = docker_url
      @connection = Docker::Connection.new(docker_url, {})
      @containers = []
      @image_pulled = false
      @mutex = Mutex.new
      @max_containers = 10
    end

    def launch_container
      @mutex.synchronize {
        if @containers.size == @max_containers
          raise Ganger::MaxContainersReached
        end
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
      }
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
    
    def dispose_of(container)
      @containers.delete_if {|c| c.id == container.id}
      container.dispose
    end
    
  end
end