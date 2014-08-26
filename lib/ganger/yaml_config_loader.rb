module Ganger
  class YamlConfigLoader
    
    def self.load_from_file(configuration, file)
      @yaml = YAML.load_file(file)
      configuration.docker_daemons = @yaml["docker_options"]["daemons"]
      configuration.docker_image = @yaml["docker_options"]["image"]
      configuration.docker_cmd = @yaml["docker_options"]["docker_cmd"]["cmd"]
      configuration.docker_args = @yaml["docker_options"]["docker_cmd"]["args"]
      configuration.docker_expose = @yaml["docker_options"]["expose"]
      
      configuration.proxy_listen_port = @yaml["ganger_options"]["listen_port"]
      configuration.service_timeout = @yaml["ganger_options"]["service_connection_timeout"]
      configuration.service_retry = @yaml["ganger_options"]["service_connection_retries"]
      configuration
    end
    
  end
end