module Ganger
  class DockerServer
    include Logging
    
    attr_reader :url, :max_containers
    
    def initialize(url, max_containers)
      @url = url
      @connection = Docker::Connection.new(url, {})
      @containers = ThreadSafe::Array.new
      @image_pulled = false
      @max_containers = max_containers
    end

    def get_container
      if containers.size == @max_containers
        raise Ganger::MaxContainersReached
      end
      loop do 
        container = create_container
        if container.service_port.nil?
          warn "Got a broken container; disposing and recreating"
          container.dispose
          sleep 1
        else
          return container
        end
      end
    end
    
    def create_container
      pull_image unless @image_pulled
      container_opts = {
        'Image' => Ganger.conf.docker.image,
        'ExposedPorts' => { Ganger.conf.docker.expose => {} }
      }
      container_opts['Cmd'] = Ganger.conf.docker.cmd if Ganger.conf.docker.cmd

      container = Docker::Container.create(container_opts, @connection)
      container.start({
        "PortBindings" => { 
          Ganger.conf.docker.expose => [{"HostPort" => ""}]
        }
      })
      DockerContainer.new(container, @url)
    end
    
    def kill_containers
      @containers.each do |container|
        container.dispose
      end
    end
    
    def containers
      Docker::Container.all(@connection)
    end
    
    def container_count
      containers.size
    end
    
    def pull_image
      Docker::Image.create({'fromImage' => Ganger.conf.docker.image}, nil, @connection)
      @image_pulled = true
    end
    
    def dispose_of_container(container)
      container.dispose
    end
    
    def to_s
      {url: @url, max_containers: @max_containers}
    end
    
    def inspect
      to_s
    end
    
  end
end