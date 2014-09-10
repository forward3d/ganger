module Ganger
  class DockerDispatcher
        
    def self.get_docker_container
      load_servers if @docker_servers.nil?
      least_utilised_docker_server.launch_container
    end
    
    def self.kill_all_containers
      @docker_servers.each do |server|
        server.kill_containers
      end
    end
    
    def self.dispose_container(container)
      # Find the parent server for this container, and tell it that the container has been disposed of
      parent_server = @docker_servers.find {|s| s.docker_url == container.docker_url}
      parent_server.dispose_of(container)
    end
    
    def self.preload_image
      load_servers if @docker_servers.nil?
      @docker_servers.each do |server|
        server.pull_image
      end
    end
    
    private
    
    def self.load_servers      
      @docker_servers = []
      Ganger.configuration.docker_daemons.each do |docker_url|
        @docker_servers << DockerServer.new(docker_url)
      end
    end
    
    def self.least_utilised_docker_server
      @docker_servers.sort_by {|ds| ds.container_count}.first
    end
    
  end
end