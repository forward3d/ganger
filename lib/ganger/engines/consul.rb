module Ganger
  module Engines
    class Consul
      include Logging
      
      def initialize
        @consul_hosts = Ganger.conf.consul_engine.hosts
        @service_name = Ganger.conf.consul_engine.service_name
        @datacenters = Ganger.conf.consul_engine.datacenters
        @default_max_containers = Ganger.conf.consul_engine.default_max_containers
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
        container.dispose
      end
      
      private
      
      def least_utilized_server
        loop do
          services = find_all_services
          
          # We can discover no servers if Consul's broken, or there are no available
          # services at the moment - loop and block until we can get a container from a server
          if services.empty?
            warn "Could not discover any servers from Consul; sleeping and retrying"
            sleep 5
            next
          end
          
          info "Discovered the following services: #{format_services(services)}"
          
          # Find the least utilized server - first look in the preferred datacenter,
          # and if any server has capacity, use that; if the DC is at capacity,
          # try the next DC, and so on. If we can't find any server, then sleep.
          least_used_server = find_least_utilized_server_by_dc_preference(services)
          if least_used_server.nil?
            info "All servers in all DCs are at capacity; sleeping and retrying"
            sleep 5
            next
          end
          
          info "Decided to use server: #{least_used_server[:server].url}, at percentage used: #{least_used_server[:percentage_used]}, in dc: #{least_used_server[:dc]}"
          return least_used_server[:server]
        end
      end
      
      def find_least_utilized_server_by_dc_preference(services)
        @datacenters.each do |dc|
          info "Looking for least used server in DC #{dc}"
          service = services.select {|s| s[:dc] == dc}.sort_by {|s| s[:percentage_used]}.first
          if service[:percentage_used] == 1
            info "All services in DC #{dc} at capacity - trying next DC"
          else
            return service
          end
        end
        nil
      end
      
      def format_services(services)
        services.map do |s| 
          "{url: #{s[:server].url}, percentage_used: #{s[:percentage_used]}}"
        end.join('; ')
      end
            
      def find_all_services
        services = []
        Ganger.conf.consul_engine.datacenters.map do |dc|
          info "Looking for service in datacenter: #{dc}"
          find_services_in_dc(dc)
        end.flatten.compact
      end
      
      def find_services_in_dc(dc)
        # Try each Consul server in turn, return nil if we can't talk to Consul
        @consul_hosts.shuffle.each do |host_and_port|
          info "Calling #{host_and_port}"
          url = "http://#{host_and_port}/v1/catalog/service/#{@service_name}?dc=#{dc}&#{@consistency_mode}"
          begin
            response = HTTParty.get(url)
            raise "Consul server returned non-200 response" if response.code != 200
            return parse_consul_response(response.body, dc)
          rescue => e
            info "#{e.class}: #{e.message}"
          end
        end
        nil
      end
      
      def parse_consul_response(response, dc)
        json = JSON.parse(response)
        docker_servers_info = json.map do |service|
          max_containers_tag = service['ServiceTags'].find {|t| t =~ /^max_containers:\d+$/}
          max_containers = max_containers_tag.empty? ? @default_max_containers : max_containers_tag.gsub('max_containers:', '')
          server = Ganger::DockerServer.new("tcp://#{service['Address']}:#{service['ServicePort']}", max_containers)
          container_count = server.container_count
          usage = container_count.to_f / max_containers.to_f
          {
            server: server,
            current_containers: container_count,
            max_containers: max_containers,
            dc: dc,
            percentage_used: usage
          }
        end
      end
      
    end
  end
end