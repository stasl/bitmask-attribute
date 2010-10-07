module BitmaskAttribute
  module Attribute
    attr_accessor :attributes
    
    def initialize(attrs = {})
      @attributes = {}
      attrs.each do |k,v|
        sym = :"#{k}="
        if respond_to? sym
          send sym, v
        else
          write_attribute(k, v)
        end
      end
    end

    def read_attribute(attr_name)
      @attributes[attr_name.to_s]
    end
    
    def write_attribute(attr_name, value)
      @attributes[attr_name.to_s] = value
    end
  end
end
