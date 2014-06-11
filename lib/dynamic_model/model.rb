module DynamicModel
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def dynamic_class_type
        self.class.name
      end
      
      # Anadir una columna dinamica
      # *params*: 
      #  *name* 
      #  *type*
      #  *length*
      #  *required*
      def add_dynamic_column params
        dynamic_scope.create!(params)
      end

      # Borrar una columna existente
      def del_dynamic_column name
        dynamic_scope.where(:name => name).first.destroy
      end

      # Devuelve solamente los nombres de las columnas 
      # dinamicas de este modelo      
      def dynamic_column_names
        dynamic_scope.select('name').map(&:name)
      end
    
      # Devuelve un hash nombre => parametros con la informacion 
      # de todas las columnas dinamicas
      def dynamic_columns
        dynamic_scope.inject(Hash.new(0)) do |res, record|
          res[record.name] = record.to_hash
          res
        end
      end
      
      # Devuelve la informacion de una columna en concreto
      def dynamic_column name
        dynamic_scope.where(:name => name).first.to_hash
      end 
    
      def dynamic_scope
        DynamicModel::Attribute.where(:class_type => dynamic_class_type)
      end
      
    end
    
    # Devuelve el valor de una columna en concreto
    def dynamic_value name
      attribute_record = self.class.dynamic_scope.where(:name => name).first
      value_record = DynamicModel::Value
        .with_dynamic_attribute(attribute_record)
        .with_item_id(self.object_id)
        .first
        
      # Parsear el valor dependiendo del tipo
      #DynamicModel::Attribute.encoder(attribute_record.type).new(attribute_record, value_record).value
      DynamicModel::Attribute.decode_value(attribute_record.type,attribute_record.default)
    end
    
  end
end