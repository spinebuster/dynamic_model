module DynamicModel
  module Type
    class Base
      class << self
        def create_encoder(params)
          # Factory
          get_encoder_by_type(params[:type]).new(params)
        end
        
        def get_encoder_by_type(type)
          # Factory
          "::DynamicModel::Type::#{type.camelize}".constantize
        end

        # Supported data types
        def types
          %w(string boolean date integer float text)
        end
        
        # Test if the value is valid
        # *params*:
        #   *max_length*: Max valid length
        #   *required* : Required value
        # Returns an array of error definitions 
        #def errors(value, params)
        #  # TODO: Do a real validate test
        #  #   depending also on the type
        #  e = []
        #  e << "is required" if params[:required] and !value
        #  e 
        # end
      end # class << self
      
      # params: A hash with the following information:
      # * type:
      # * required: 
      # * length: 
      def initialize(params)
        @params = params
        @errors = []
      end
      
      # Convert it to store on the DB
      def encode(value)
        # nil has no conversion
        return nil if value.nil?
        
        # Use yaml as the serializer
        value.to_yaml
      end
      
      # Convert it from the format of the DB
      def decode(value)
        # nil has no conversion
        return nil if value.nil?

        YAML.load(value)
      end
    end
  end
end