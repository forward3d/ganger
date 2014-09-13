module Ganger
  module Engines
    class Static
      include Logging
      
      # The static engine reads Docker servers from a config file.
      
      def initialize
        @docker_servers = Ganger.conf.docker.daemons.map do |opts|
          info "Discovered container with url: #{opts[:url]}; max containers: #{opts[:max_containers]}"
          DockerServer.new(opts[:url], opts[:max_containers])
        end
      end
      
      # Engines support the following methods: pull_image, get_container, dispose_of_container
      
      def pull_image
        @docker_servers.each {|s| s.pull_image}
      end
      
      def get_container
        loop do
          begin
            return least_utilized_server.get_container
          rescue MaxContainersReached => e
            info "Least utilized server is at max containers; sleeping and retrying"
            sleep 5
          end
        end
      end
      
      def dispose_of_container(container)
        @docker_servers.find {|s| s.url == container.server_url}.dispose_of_container(container)
      end
      
      private
      
      def least_utilized_server
        @docker_servers.sort_by {|ds| ds.container_count}.first
      end
      
    end
  end
end