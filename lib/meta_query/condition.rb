module MetaQuery    
  class Condition
    attr_reader :column_name, :operation, :value, :condition_type,
                :parametrizable, :value_type, :parent_model
    attr_accessor :parameter_description
    
    def initialize(column_name, operation, value, condition_type = nil, parametrizable = false, value_type = nil, parent_model = nil)
      @column_name = column_name
      @operation = operation
      @value = value
      @condition_type = condition_type if condition_type
      @parametrizable = parametrizable
      @value_type = value_type
      @parent_model = parent_model
    end
    
    def parametrized?
      return (@parametrizable == "true") if @parametrizable.class == String
      @parametrizable
    end
    alias parametrizable? parametrized?
    
    def set_parametrized_value(value)
      raise QueryException, "Condition not parametrizable" unless parametrizable?
      @value = value
      return self
    end
    
    def single_condition
      @condition_type = nil
    end
    
    def sql_value      
      case @value.class.to_s
        when "String"
          return "'#{@value}'"
        else
          return @value
      end
        
    end
    
    def to_sql
      "#{parent_model.id}.\"#{column_name}\" #{operation} #{sql_value}"
    end
    
  end
end
