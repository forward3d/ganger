module Ganger
  class DockerManager
    
    attr_accessor :engine
    
    def pull_image
      @engine.pull_image
    end
    
    def get_container
      @engine.get_container
    end
    
    def dispose_of_container(container)
      @engine.dispose_of_container(container)
    end
    
  end
end