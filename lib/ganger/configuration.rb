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