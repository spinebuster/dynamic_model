# Represent a definition of an attribute.
# It provides a common mechanism to transfer attribute definition
# accross a broad range of modules and classes, connected and disconnected
module DynamicModel
  class AttributeDefinition
    
    attr_accessor :class_type, :name, :type, :length, :required, :default
    
    def initialize(params)
      params.each{|k, v| self.send("#{k}=", v)}
    end
    
    def to_hash
      {
        :class_type => class_type,
        :name => name.to_sym,
        :type => type,
        :length => length,
        :required => required,
        :default => default
      }
    end
    
    def encoder
      DynamicModel::Type::Base.create_encoder({
        :type => self.type,
        :length => self.length,
        :required => self.required,
        :default => self.default
      })
    end
    
    def encode(value)
      encoder.encode(value)
    end

    def decode(value)
      encoder.decode(value)
    end
    
    
  end
end