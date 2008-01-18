module MetaQuery
class Model
    attr_reader :id, :parent_id, :model_name, :position, :possible_columns,
                :possible_associations, :joins, :hidden
    attr_accessor :conditions, :fields, :join_type
    
    def initialize(parent_id, model_name, position, possible_columns = nil,
                   possible_associations = nil, hidden = false)
      @parent_id = parent_id                 
      @model_name = model_name
      @position = position
      @possible_columns = possible_columns if possible_columns
      @possible_associations = possible_associations if possible_associations
      @hidden = hidden
      
      @joins = []
      @conditions = []
      @fields = []
      
      generate_id!
    end
    
    def name; @model_name; end
    
    def belongs_to?(related_model_name)
      #raise "#{related_model_name} pa =" + @possible_associations.to_json
      return false if @possible_associations.nil?
      
      related_model_name = related_model_name.to_s.underscore.singularize
      belongs_to_key = (@possible_associations[related_model_name.to_s] ? related_model_name.to_s : related_model_name.to_sym)
      return false if @possible_associations[belongs_to_key].nil?
      
      return (@possible_associations[belongs_to_key] == "belongs_to") || (@possible_associations[belongs_to_key] == :belongs_to)
#      (@possible_associations[belongs_to_key].include? related_model_name) || (@possible_associations[belongs_to_key].include? related_model_name.classify)
    end
    
    # Returns true if the model is root (has no parents).
    def is_root?; parent_id.nil?; end
    
    def parametrized?
      conditions.any? {|c| c.parametrized? }
    end
    alias parametrizable? parametrized?

    def set_parametrized_condition_value(condition_index, value)
      @conditions[condition_index].set_parametrized_value(value)
    end
    
    # Returns the table name
    def table_name; @model_name.tableize; end
    
    # Adds a new model as a join into the current model
    def add_join(model, join_type)
      model.join_type = join_type || DEFAULT_JOIN_TYPE
      @joins << model
    end
    
    def add_field(column_name, as_name, field_type = nil)
      raise "The #{column_name} don't exists for the model #{@model_name}" \
        if !@possible_columns.nil? && !@possible_columns.keys.include?(column_name)
      
      (@fields << Field.new(column_name, as_name, field_type, self)).last
    end
    
    def add_condition(column_name, operation, value, condition_type, parametrizable)
      if @possible_columns
        field_type = @possible_columns[column_name]
        raise "Column #{column_name} don't exist on model #{@model_name}" if field_type.nil?      
      else
        field_type = nil
      end
      (@conditions << Condition.new(column_name, operation, value, condition_type, parametrizable, field_type.to_sym, self)).last
    end
    
    # Removes the condition with given index from the model. Returns the
    # removed condition.
    def remove_condition(index)
      cond = @conditions.delete_at index
      @conditions[0].single_condition if @conditions.size == 1      
      return cond
    end

    # Removes the field with given index from the model. Returns the
    # removed field.
    def remove_field(index)
      @fields.delete_at index
    end
    
    # Returns the index of the condition in the conditions list.
    def condition_index(condition)
      @conditions.index condition
    end
    
    # Returns a symbol with the data type of the given column
    def field_type(column_name)
      type = @possible_columns[column_name]
      raise "Column #{column_name} don't exist in model #{name}." unless type
      type.to_sym
    end
    
    private
    # Creates a uniq id for the current model
    def generate_id!
      suffix = @parent_id ? "#{@parent_id}_" : ""
      @id = suffix + @model_name.classify + "_#{@position[0]}_#{@position[1]}"
      @id = @id.downcase
      #TODO: convert the string into a hash code in order to minimize the sql lenght. 
    end
  end
end