require 'bitmask_attribute/value_proxy'
require 'bitmask_attribute/attribute'
require 'bitmask_attribute/core_ext/hash_with_indifferent_access' unless defined?(HashWithIndifferentAccess)
require 'bitmask_attribute/core_ext/blank' unless Object.respond_to?(:blank?)

module BitmaskAttribute
  
  class Definition
    
    attr_reader :attribute, :values, :extension
    def initialize(attribute, values=[], &extension)
      @attribute = attribute
      @values = values
      @extension = extension
    end
    
    def install_on(model)
      validate_for model
      generate_bitmasks_on model
      override model
      create_convenience_class_method_on(model)
      create_convenience_instance_methods_on(model)
      create_named_scopes_on(model) if defined?(ActiveRecord::Base) && model.respond_to?(scope_method)
    end
    
    #######
    private
    #######

    def validate_for(model)
      unless (model.columns.detect { |col| col.name == attribute.to_s } rescue true)
        raise ArgumentError, "`#{attribute}' is not an attribute of `#{model}'"
      end
    end
    
    def generate_bitmasks_on(model)
      model.bitmasks[attribute] = HashWithIndifferentAccess.new.tap do |mapping|
        values.each_with_index do |value, index|
          mapping[value] = 0b1 << index
        end
      end
    end
    
    def override(model)
      override_getter_on(model)
      override_setter_on(model)
    end
    
    def override_getter_on(model)
      model.class_eval %(
        def #{attribute}
          @#{attribute} ||= BitmaskAttribute::ValueProxy.new(self, :#{attribute}, &self.class.bitmask_definitions[:#{attribute}].extension)
        end
      )
    end
    
    def override_setter_on(model)
      model.class_eval %(
        def #{attribute}=(raw_value)
          values = raw_value.kind_of?(Array) ? raw_value : [raw_value]
          self.#{attribute}.replace(values.reject(&:blank?))
        end
      )
    end
    
    def create_convenience_class_method_on(model)
      model.class_eval %(
        def self.bitmask_for_#{attribute}(*values)
          values.inject(0) do |bitmask, value|
            unless (bit = bitmasks[:#{attribute}][value])
              raise ArgumentError, "Unsupported value for #{attribute}: \#{value.inspect}"
            end
            bitmask | bit
          end
        end
      )
    end


    def create_convenience_instance_methods_on(model)
      values.each do |value|
        model.class_eval %(
          def #{attribute}_for_#{value}?                  
            self.#{attribute}?(:#{value})
          end
        )
      end
      model.class_eval %(
        def #{attribute}?(*values)
          if !values.blank?
            values.all? do |value|
              self.#{attribute}.include?(value.to_sym)
            end
          else
            self.#{attribute}.present?
          end
        end
      )
    end

    def scope_method
      ActiveRecord::VERSION::STRING >= "3" ? :scope : :named_scope
    end

    def create_named_scopes_on(model)
      model.class_eval %(
        #{scope_method} :with_#{attribute},
          proc { |*values|
            if values.blank?
              {:conditions => '#{attribute} > 0 OR #{attribute} IS NOT NULL'}
            else
              mask = #{model}.bitmask_for_#{attribute}(*values)
              {:conditions =>"#{attribute} & \#{mask} = \#{mask}"}
            end
          }
        #{scope_method} :with_#{attribute}_in,
          proc { |value, *other_values|
            mask = #{model}.bitmask_for_#{attribute}(value, *other_values)
            {:conditions => "#{attribute} & \#{mask} <> 0"}
          }
        #{scope_method} :without_#{attribute}, :conditions => "#{attribute} == 0 OR #{attribute} IS NULL"
        #{scope_method} :no_#{attribute},      :conditions => "#{attribute} == 0 OR #{attribute} IS NULL"
      )
      values.each do |value|
        model.class_eval %(
          #{scope_method} :#{attribute}_for_#{value},
                          :conditions => ['#{attribute} & ? <> 0', #{model}.bitmask_for_#{attribute}(:#{value})]
        )
      end      
    end
    
  end

  def self.included(model)
    model.extend ClassMethods
    # Include basic attributes support for clean class
    # TODO improve attributes detection
    model.send(:include, BitmaskAttribute::Attribute) unless model.included_modules.detect{|m| m.to_s.include? 'AttributeMethods'}
  end

  module ClassMethods
    
    def bitmask(attribute, options={}, &extension)
      unless options[:as] && options[:as].kind_of?(Array)
        raise ArgumentError, "Must provide an Array :as option"
      end
      bitmask_definitions[attribute] = BitmaskAttribute::Definition.new(attribute, options[:as].to_a, &extension)
      bitmask_definitions[attribute].install_on(self)
    end
    
    def bitmask_definitions
      @bitmask_definitions ||= {}
    end
    
    def bitmasks
      @bitmasks ||= {}
    end
      
  end
  
end

ActiveRecord::Base.send :include, BitmaskAttribute if defined? ActiveRecord::Base
