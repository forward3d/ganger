module Ganger
  module Engines
    class Consul
      include Logging
      
      def initialize
        @consul_hosts = Ganger.conf.consul_engine.hosts
        @server_cache = {}
      end
      
      def config_valid?
        valid = true
        if @consul_hosts.nil?
          warn "No Consul hosts supplied!"
          valid = false
        end
        valid
      end
      
      def pull_image
        info "Image pulls are skipped during Consul engine usage"
      end
      
      def get_container
        least_utilized_server.get_container
      end
      
      def dispose_of_container(container)
        discovered_docker_servers.find {|s| s.url == container.server_url}.dispose_of_container(container)
      end
      
      private
      
      def least_utilized_server
        loop do
          servers = discovered_docker_servers
          
          # We can discover no servers if Consul's broken, or there are no available
          # services at the moment - loop and block until we can get a container from a server
          if servers.empty?
            warn "Could not discover any servers from Consul; sleeping and retrying"
            sleep 5
            next
          end
          
          # Find the least utilized server
          percentage_used_servers = servers.map do |server|
            current_containers = @server_cache[server.url].to_f || 0.to_f
            percentage_used = current_containers / server.max_containers.to_f
            { server: server, percentage_used: percentage_used }
          end
          least_used_server = percentage_used_servers.sort_by {|s| s[:percentage_used] }.first
          return least_used_server[:server]
        end
      end
      
      def discovered_docker_servers
        docker_servers = []
        @consul_hosts.shuffle.each do |host_and_port|
          begin
            
            json = JSON.parse(
              HTTParty.get(
                "http://#{host_and_port}/v1/catalog/service/#{Ganger.conf.consul_engine.service_name}?#{Ganger.conf.consul_engine.consistency_mode}"
              ).body)
              
            docker_servers = json.map do |service|
              max_containers_tag = service['ServiceTags'].find {|t| t =~ /^max_containers:\d+$/}
              max_containers = max_containers_tag.empty? ? Ganger.conf.consul_engine.default_max_containers : max_containers_tag.gsub('max_containers:', '')
              Ganger::DockerServer.new("tcp://#{service['Address']}:#{service['ServicePort']}", max_containers)
            end
            break
          rescue Timeout::Error => e
            warn "Timeout attempting to contact Consul server: #{host_and_port}; trying next server"
          rescue JSON::ParserError => e
            warn "JSON parsing of Consul API response from #{host_and_port} failed; trying next server"
          rescue => e
            warn "Some exception (#{e.class}: #{e.backtrace}) occurred speaking to the Consul API on #{host_and_port}; trying next server"
          end
        end
        info "Docker servers discovered via Consul: #{docker_servers.to_s}"
        docker_servers
      end
      
    end
  end
end