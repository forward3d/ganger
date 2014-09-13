module Ganger
  module Logging
    
    @@logger = Logger.new(STDOUT)
    
    def info(msg)
      @@logger.info(msg)
    end
    
    def warn(msg)
      @@logger.warn(msg)
    end
    
    def fatal(msg)
      @@logger.fatal(msg)
    end
    
  end
end