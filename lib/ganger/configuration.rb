require 'ostruct'

module Ganger
  class Configuration
    include Logging
    
    def initialize
      # Set defaults
      self.ganger.listen_port = 5454
      self.ganger.service_connection_timeout = 5
      self.ganger.service_connection_retries = 6
      self.ganger.docker_timeout = 300
      self.ganger.docker_discovery = 'static'
    end
    
    def method_missing(method_sym, *args, &block)
      if instance_variable_get("@#{method_sym.to_s}").nil?
        instance_variable_set("@#{method_sym.to_s}", OpenStruct.new)
      end
      instance_variable_get("@#{method_sym.to_s}")
    end
    
    def valid?
      info "Validating configuration"
      valid = true
      
      # Require at least one Docker daemon
      if Ganger.conf.docker.daemons.nil?
        warn "docker.daemons: At least one docker daemon is required"
        valid = false
      end
      
      # Require Docker daemons be supplied as array of hashes
      unless Ganger.conf.docker.daemons.is_a?(Array)
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

      # An image must be supplied
      if Ganger.conf.docker.image.nil?
        warn "docker.image: No image supplied"
        valid = false
      end
      
      # A port that container exposes must be specified
      if Ganger.conf.docker.expose.nil?
        warn "docker.expose: No expose port specified"
        valid = false
      else
        unless Ganger.conf.docker.expose =~ /^\d+\/tcp$/
          warn "docker.expose: Should be specified as port/tcp; e.g. 12345/tcp"
          valid = false
        end
      end
      
      valid
      
    end
    
    def inspect
      to_s
    end
    
    def to_s
      self.instance_variables.sort.map do |var|
        { var => instance_variable_get(var).to_h }
      end
    end
    
  end
end