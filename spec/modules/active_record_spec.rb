require File.join(File.dirname(__FILE__), "..", "spec_helper")

  def each_column_datatype(type_list = nil)
    type_list ||= DynamicModel::Type::Base.types
    type_list = [type_list] if type_list.is_a?(String)
    
    type_list.each do |type|
      yield(type)
    end
  end

  # Params:  
  # * class_type
  # * name
  # * type
  # * length
  # * required
  # * default
  def db_add_column(definition) 
    encoder = definition.encoder
    sql = "INSERT INTO dynamic_attributes (`class_type`,`name`,`type`,`length`,`required`,`default`,`created_at`,`updated_at`) VALUES ('%{class_type}','%{name}', '%{type}', %{length}, %{required}, %{default},'%{created_at}','%{updated_at}');"
    definition.required = definition.required ? 1 : 0
    definition.default = definition.default.nil? ? 'NULL' : "'#{encoder.encode(definition.default)}'" 
    ActiveRecord::Base.connection.execute(sql % definition.to_hash.merge(:created_at => Time.now.strftime("%Y-%m-%d %H:%M:%S"), :updated_at => Time.now.strftime("%Y-%m-%d %H:%M:%S")))
  end
  
  def db_upd_column(definition)
    encoder = definition.encoder
    sql = "UPDATE dynamic_attributes set `default`= %{default}, `length` = %{length}, `required` = %{required} where `class_type` = '%{class_type}' and `name` = '%{name}';"
    definition.required = definition.required ? 1 : 0
    definition.default = definition.default.nil? ? 'NULL' : "'#{encoder.encode(definition.default)}'" 
    ActiveRecord::Base.connection.execute(sql % definition.to_hash)
  end

describe "ActiveRecord" do
  before(:all) do
    @defaults = {
        :string => "Other",
        :boolean => false,
        :date => Date.today - 2,
        :integer => 34567,
        :float => 45.23,
        :text => (1..350).map { (('a'..'z').to_a + ('0'..'9').to_a).sample }.join
      }
    @values = {
      :string => "Some",
      :boolean => true,
      :date => Date.today,
      :integer => 76543,
      :float => 87.34,
      :text => (1..350).map { (('a'..'z').to_a + ('0'..'9').to_a).sample }.join
    }
    
    each_column_datatype do |type|
      begin
        # Asegurarse de que no existe la columna en el BD
        sql = %Q(ALTER TABLE test_table DROP COLUMN `name_%{type}`;)
        ActiveRecord::Base.connection.execute(sql % { type: type.to_s })
      rescue Exception => ex
        puts "WARNING -> #{ex.message}"
      end
    end
  end
  
#  class TestAR < ActiveRecord::Base
#    include DynamicModel::Model
#    self.table_name = "test_table"
#    has_dynamic_columns
#  end
    
  def set_class_and_record
    build_model :test_classes do
      string :name
      # attr_accessible :name
      has_dynamic_columns
    end
    klass = TestClass
    
#    Class.new(ActiveRecord::Base).class_eval do
#      self.table_name = "test_table"
#      include DynamicModel::Model
#      has_dynamic_columns
#    end
    name = "Test name"
    record = klass.new(:name => name) 
    record.name.should == name
    [klass, record]
  end
  
  it "should save strings with accents" do
    @klass, @record = set_class_and_record
    definition = DynamicModel::AttributeDefinition.new({
      :class_type => @klass.name,
      :name => "name_string",
      :type => "string",
      :length => 50,
      :required => false,
      :default => nil
    })
    
    @name_string = "áéíóú"
    @record.name_string = @name_string
    @record.save
    
    @record.reload
    expect(@record.name_string).to eql(@name_string)
  end
  
  
  each_column_datatype('string') do |type|
    before(:each) do
      @klass, @record = set_class_and_record
      definition = DynamicModel::AttributeDefinition.new({
        :class_type => @klass.name,
        :name => "name_#{type}",
        :type => type,
        :length => 50,
        :required => false,
        :default => nil
      })
      db_add_column(definition)
    end
    
    context "dynamic_column_names" do
      it "should return an array with all the dynamic columns" do
        expect(@klass.dynamic_column_names).to eql(["name_#{type}"])
      end
    end

    # initialize
    context "initialize" do
      context "assign dynamic attributes" do
        it "should return the dynamic attributes empty for #{type} type" do
          @record.send("name_#{type}").should be_nil
        end
        
        context "with a default value" do
          before(:each) do
            definition = DynamicModel::AttributeDefinition.new({
              :class_type => @klass.name,
              :name => "name_#{type}",
              :type => type,
              :length => 50,
              :required => false,
              :default => @defaults[type.to_sym]
            })
              
            # Set the default value    
            db_upd_column(definition)
          end
          
          it "should return the dynamic attributes with the default value for #{type} type" do
            @record.send("name_#{type}").should == @defaults[type.to_sym]
          end
        end
        
        context "with a value" do
          it "should return the dynamic attributes with the value for #{type} type" do
            # Set to a test value
            @record.send("name_#{type}=", @values[type.to_sym])
            @record.send("name_#{type}").should == @values[type.to_sym]
          end
        end
      end # context "assign dynamic attributes"
    end # context "initialize"
    
    context "save" do
      describe "with no values given for dynamic columns" do
        it "should not create value records without default value for #{type} type" do
          expect{
            @record.save
          }.to change(DynamicModel::Value,:count).by(0)
        end
  
        it "should not create value records with default value for #{type} type" do
          definition = DynamicModel::AttributeDefinition.new({
            :class_type => @klass.name,
            :name => "name_#{type}",
            :type => type,
            :length => 50,
            :required => true,
            :default => @defaults[type.to_sym]
          })
            
          # Set the default value    
          db_upd_column(definition)   
          expect{
            @record.save
          }.to change(DynamicModel::Value,:count).by(0)
          @record.send("name_#{type}").should == @defaults[type.to_sym]
        end
      end
      
      describe "with value given for dynamic columns" do
        before(:each) do
          @record = @klass.new(:name => "Test", :"name_#{type}" => @values[type.to_sym])
        end # before(:each)
        it "should create a value record with the value given for #{type} type" do
          expect{
            @record.save
          }.to change(DynamicModel::Value,:count).by(1)
          @record.send("name_#{type}").should == @values[type.to_sym]
        end
      end
    end # context "create"
  
    context "create!" do
      describe "with no values given for dynamic columns" do
        it "should not create value records without default value for #{type} type" do
          record = nil
          expect{
            record = @klass.create!(:name => "Test")
          }.to change(DynamicModel::Value,:count).by(0)
          record.send("name_#{type}").should be_nil
        end
  
        it "should not create value records with default value for #{type} type" do
          definition = DynamicModel::AttributeDefinition.new({
            :class_type => @klass.name,
            :name => "name_#{type}",
            :type => type,
            :length => 50,
            :required => true,
            :default => @defaults[type.to_sym]
          })
            
          # Set the default value    
          db_upd_column(definition)   
          record = nil
          expect{
            record = @klass.create!(:name => "Test")
          }.to change(DynamicModel::Value,:count).by(0)
          record.send("name_#{type}").should == @defaults[type.to_sym] 
        end
      end
      
      describe "with value given for dynamic columns" do
        it "should create a value record with the value given for #{type} type" do
          record = nil
          expect{
            record = @klass.create!(:name => "Test", :"name_#{type}" => @values[type.to_sym])
          }.to change(DynamicModel::Value,:count).by(1)
          record.send("name_#{type}").should == @values[type.to_sym] 
        end
      end
    end # context "create"
  
    context "update_attributes" do
      before(:each) do
        @record.save
      end # before(:each)

      describe "with no values given for dynamic columns" do
        it "should not create value records without default value for #{type} type" do
          expect{
            @record.update_attributes!(:name => "Test")
          }.to change(DynamicModel::Value,:count).by(0)
          @record.send("name_#{type}").should be_nil 
        end
  
        it "should not create value records with default value for #{type} type" do
          definition = DynamicModel::AttributeDefinition.new({
            :class_type => @klass.name,
            :name => "name_#{type}",
            :type => type,
            :length => 50,
            :required => true,
            :default => @defaults[type.to_sym]
          })
            
          # Set the default value    
          db_upd_column(definition)   
          expect{
            @record.update_attributes!(:name => "Test")
          }.to change(DynamicModel::Value,:count).by(0)
          @record.send("name_#{type}").should == @defaults[type.to_sym] 
        end
      end
      
      describe "with value given for dynamic columns" do
        it "should create a value record with the value given for #{type} type" do
          expect{
            @record.update_attributes!(:name => "Test", :"name_#{type}" => @values[type.to_sym])
          }.to change(DynamicModel::Value,:count).by(1)
          @record.send("name_#{type}").should == @values[type.to_sym] 
        end
        
        
        it "should return null after resetting the value" do
          @record.update_attributes!(:name => "Test", :"name_#{type}" => @values[type.to_sym])
          
          @record.update_attributes!(:name => "Test", :"name_#{type}" => nil)
          expect(@record.send(:"name_#{type}")).to be_nil
        end
        
      end
    end # context "create"
    
    context "delete" do
      before(:each) do
        @record.update_attributes!(:"name_#{type}" => @values[type.to_sym])
      end
      describe "with value given for dynamic columns" do
        it "should delete the value record with the value given for #{type} type" do
          expect{
            @record.destroy
          }.to change(DynamicModel::Value,:count).by(-1)
        end
      end
    end # context "create"
    
    context "find" do
      describe "with no values given for dynamic columns" do
        before(:each) do
          definition = DynamicModel::AttributeDefinition.new({
            :class_type => @klass.name,
            :name => "name_#{type}",
            :type => type,
            :length => 50,
            :required => true,
            :default => @defaults[type.to_sym]
          })
            
          # Set the default value    
          db_upd_column(definition)
          @record.save
        end
        it "should return the default value for #{type} type" do
          r = @klass.find_by_name(@record.name)
          r.send("name_#{type}").should == @defaults[type.to_sym] 
        end
      end
      
      describe "with value given for dynamic columns" do
        before(:each) do
          @record.update_attributes!(:"name_#{type}" => @values[type.to_sym])
        end
        it "should return the correct value for #{type} type" do
          r = @klass.find_by_name(@record.name)
          r.send("name_#{type}").should == @values[type.to_sym] 
        end
      end
      
      describe "should update again after finding" do
        before(:each) do
          definition = DynamicModel::AttributeDefinition.new({
            :class_type => @klass.name,
            :name => "name_#{type}",
            :type => type,
            :length => 50,
            :required => true,
            :default => @defaults[type.to_sym]
          })
            
          # Set the default value
          db_upd_column(definition)
          
          @record.save!
        end
        
        it "should return the correct value for #{type} type" do
          r = @klass.find_by_id(@record.id)
          r.update_attributes!("name_#{type}" => @values[type.to_sym])
          r.send("name_#{type}").should == @values[type.to_sym] 
        end
        
        it "should return the correct value for #{type} type" do
          r = @klass.find(@record.id)
          r.update_attributes!("name_#{type}" => @values[type.to_sym])
          r.send("name_#{type}").should == @values[type.to_sym] 
        end
      end
      
      
    end # context "create"
    
    context "del_dynamic_column" do
      before(:each) do
        @name = "name_#{type}"
        @record.update_attributes!(:"name_#{type}" => @values[type.to_sym])
        @record.send("name_#{type}").should == @values[type.to_sym]
      end
      
      it "should not find the attribute after deleting column" do
        # Quitar la columna
        @klass.del_dynamic_column(@name)
        expect(@record.respond_to?("name_#{type}")).to be_falsy

        expect{
          @record.update_attributes!(:name => "A test name")
        }.to_not raise_error
      end
      
      it "should find the attribute after deleting column and creating on the model" do
        # Quitar la columna
        @klass.del_dynamic_column(@name)
        
        # Crear la columna en la base de datos
        ActiveRecord::Base.connection.execute("ALTER TABLE test_table ADD COLUMN name_#{type} VARCHAR(45) NULL DEFAULT NULL;")
        @klass.reset_column_information

        @record.reload
        expect{
          @record.send("name_#{type}")
        }.to raise_error(NoMethodError)
        expect{
          @record.update_attributes!(:name => "A test name")
        }.to_not raise_error
      end
    end
    
    context "read_attribute" do
      before(:each) do
        @name = "name_#{type}"
        @record.update_attributes!(:"name_#{type}" => @values[type.to_sym])
        @record.send("name_#{type}").should == @values[type.to_sym]
      end
      
      it "should respond to read_attribute correctly" do
        expect(@record.read_attribute(:"name_#{type}")).to eql(@values[type.to_sym])
      end
    end
  end # each_column_datatype
end
 