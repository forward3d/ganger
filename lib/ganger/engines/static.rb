module Ganger
  module Engines
    class Static
      include Logging
      
      # The static engine reads Docker servers from a config file.
      
      def initialize
        Ganger.conf.static_engine.daemons.map! do |hash|
          hash[:url] == 'boot2docker' ? {url: find_boot2docker_ip, max_containers: hash[:max_containers]} : hash
        end
        @docker_servers = Ganger.conf.static_engine.daemons.map do |opts|
          info "Discovered container with url: #{opts[:url]}; max containers: #{opts[:max_containers]}"
          DockerServer.new(opts[:url], opts[:max_containers])
        end
      end
      
      # Engines support the following methods: config_valid?, pull_image, get_container, dispose_of_container
      
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
      
      def config_valid?
        valid = true
        
        # Require at least one Docker daemon
        if Ganger.conf.static_engine.daemons.nil?
          warn "docker.daemons: At least one docker daemon is required"
          valid = false
        end
      
        # Require Docker daemons be supplied as array of hashes
        unless Ganger.conf.static_engine.daemons.is_a?(Array)
          warn "docker.daemons: Must be an array of hashes"
          valid = false
        else
          Ganger.conf.daemons.each do |daemon_conf|
            if daemon_conf.is_a?(Hash)
              if daemon_conf[:url].nil?
                warn "docker.daemons: Hash is missing symbol param ':url'" 
                valid = false
              end
              if daemon_conf[:max_containers].nil?
                warn "docker.daemons: Hash is missing symbol param ':max_containers'"
                valid = false
              end
            else
              warn "docker.daemons: Member of array is not a hash: #{daemon_conf}" unless daemon_conf.is_a?(Hash)
              valid = false
            end
          end
        end
        valid
      end
      
      private
      
      def least_utilized_server
        @docker_servers.sort_by {|ds| ds.container_count}.first
      end
      
      def find_boot2docker_ip
        output = `/usr/local/bin/boot2docker ip 2>/dev/null`
        if $?.exitstatus != 0
          raise "boot2docker was specified as one of the docker daemons, but it could not be run!"
        end
        "tcp://#{output}:2375"
      end
      
    end
  end
end