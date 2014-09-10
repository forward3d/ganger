require 'ostruct'

module Ganger
  class Configuration
    
    def method_missing(method_sym, *args, &block)
      if instance_variable_get("@#{method_sym.to_s}").nil?
        instance_variable_set("@#{method_sym.to_s}", OpenStruct.new)
      end
      instance_variable_get("@#{method_sym.to_s}")
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