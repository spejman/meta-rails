require "sqldsl-1.4.2/sqldsl.rb"

require "rubygems"
require "active_support"


module MetaQuery
  DEFAULT_JOIN_TYPE = "left outer"
  DEFAULT_CODITION = "AND"
  
  class QueryException < Exception; end
  class CodeInjectionWarning < QueryException; end
  class Query
    attr_reader :root
    
    def initialize
      @root = []
      @models_by_key = {}
    end
    
    def to_json
      @models_by_key.to_json
    end
    
    # Adds a model to the query, creates the join between the new model and
    # the parent model. Finally, returns the new model object.
    # In order to generate the sql, possible_columns and possible_associations must be
    # given like:
    # possible_columns =  {"label" => "string", "name" => "string", "order" => "integer"}
    # possible_associations = {:has_many => ["lexical_entries", ..., "senses"], :belongs_to => ["lexicon", ..., "lexical_resource"]}
    def add_model(parent_id, model_name, position, possible_columns = nil, possible_associations = nil, join_type = nil)
      new_model = Model.new parent_id, model_name, position, possible_columns, possible_associations
      raise QueryException, "Model #{new_model.id} already exists" if @models_by_key[new_model.id]
      @models_by_key[new_model.id] = new_model
      
      # if is the root model, return the model
      if parent_id.nil?
        @root << new_model
        return new_model
      end
      
      # if isn't the root model check if the parent exists and add the join
      parent = @models_by_key[parent_id]
      raise QueryException, "Parent with id #{parent_id} does not exist." unless parent
      parent.add_join(new_model, join_type)
      
      return new_model
    end
    
    # Adds a condition to the model, returns the created condition.
    def add_condition(model_id, column_name, operation, value, condition_type = nil)
      model = get_model model_id
      (model.conditions << Condition.new(column_name, operation, value, condition_type)).last
    end
    
    # Adds a field to the model, returns the created field.
    def add_field(model_id, column_name, as_name)
      model = get_model model_id
      (model.fields << Field.new(column_name, as_name)).last
    end

    # Removes the model and all its children!!! and associated data (conditions,
    # fields) from the query and from the joins of its parents.
    def remove_model(model_id)
      model_id = model_id.id if model_id.class == MetaQuery::Model
      model_to_remove = get_model(model_id)
      raise "Model with model_id #{model_id} doesn't exist" if model_to_remove.nil?
      @models_by_key.delete model_id
      
      # if the model has parents remove it from its join list.
      parent = get_model(model_to_remove.parent_id) 
      parent.joins.delete model_to_remove if parent
      
      # if the model is root remove it form the root array
      @root.delete model_to_remove if model_to_remove.is_root?
    end
    
    # Go through all the models of the query (unordered).
    def each_model
      @models_by_key.values.each do |model| 
        yield(model)
      end
    end
    
    # Returns a array with all the models
    def models
      @models_by_key.values
    end
    
    # Returns the model identified by model_id
    def get_model(model_id)
      return @models_by_key[model_id]
    end
    
    # Returns the SQL sentence for the query
    def to_sql
      fields = all_fields_sql.collect {|field| field.to_sym }
      st = Select[fields]
      
      from_tables = all_from_tables.collect {|table| table[0].to_sym.as table[1].to_sym}
      st.from[from_tables]
      
      joins = all_joins_sql
      joins.each do |join_def|
        st.inner_join[join_def[1]]
       # raise join_def[2]
        st.on { eval join_def[2] }
      end
      
      conditions = all_conditions
      unless conditions.empty?
        st.where { eval conditions.shift[1] }
        conditions.each do |cond|
          if cond[0] == "AND"
            st.and { eval cond[1] }
          elsif cond[0] == "OR"
            st.or { eval cond[1] }
          else
            raise QueryException, "Condition \"#{cond[0]}\" not supported."
          end
        end
      end
      
      st.to_sql
    end
    
    # Returns a array with all the fields and its "as" values in this form:
    # [ "model_id.field_name_1 as field_as_1" , ..., "model_id.field_name_N as field_as_N" ]
    def all_fields_sql
      fields = []; each_model do |model|
        fields += model.fields.collect {|f| "#{model.id}.#{f.column_name} as #{f.as_name}" }
      end
      fields
    end
    
    # Returns a array with all the root models tables names and its identifiers in this form:
    # [ [ table_name_1, table_id_1 ], ..., [ table_name_N, table_id_N ] ]
    def all_from_tables
      from_tables = []; @root.each do |root_model|
        from_tables << [root_model.table_name, root_model.id]
      end
      from_tables
    end
    
    def all_joins_sql      
      joins = []; each_model do |model|
        model.joins.each do |join_model|
          if !model.belongs_to?(join_model.model_name) && !join_model.belongs_to?(model.model_name)
            habtm_join_table = [join_model.table_name, model.table_name].join "_"
            habtm_join_id = model.id + join_model.id
            join_type = join_model.join_type #TODO: think if is the correct join type
            join_table = habtm_join_table.to_sym.as(habtm_join_id.to_sym)
            join_condition = "#{model.id}.id == #{habtm_join_id}.#{model.model_name.underscore}_id"
            check_for_code_injection(join_condition)
            joins << [join_type, join_table, join_condition]
            
            
            join_type = join_model.join_type #TODO: think if is the correct join type
            join_table = join_model.table_name.to_sym.as(join_model.id.to_sym)
            join_condition = "#{habtm_join_id}.#{join_model.model_name.underscore}_id == #{ join_model.id}.id"
            check_for_code_injection(join_condition)
            joins << [join_type, join_table, join_condition]
            
          else
            join_type = join_model.join_type
            join_table = join_model.table_name.to_sym.as(join_model.id.to_sym)
            join_condition = "#{model.id}." + (model.belongs_to?(join_model.model_name) ? "#{join_model.model_name.underscore}_id" : "id") \
              + " == #{join_model.id}." + (join_model.belongs_to?(model.model_name) ? "#{model.model_name.underscore}_id" : "id")
            check_for_code_injection(join_condition)
            joins << [join_type, join_table, join_condition]
          end
        end     
      end  
      joins
    end
    
    def all_conditions
      conditions = []; each_model do |model|
        model.conditions.each do |cond|
          cond_declaration = "#{model.id}.#{cond.column_name} #{cond.operation} #{cond.value}"
          check_for_code_injection(cond_declaration)
          conditions << [cond.condition_type || DEFAULT_CODITION, cond_declaration]
        end
      end
      conditions
    end
    
    private
    # Checks a if string tries to do a code injection hack
    # having in mind that this string will be used into a eval()
    # call begining and ending it with ".
    #
    # Example:
    #   "\"; File.rm('../config/*'); \""
    def check_for_code_injection(instruction)
      ci = instruction.gsub("\\", "")
      ci.gsub!("\"", "")
      return if (ci.count("\"") == 0)
      raise CodeInjectionWarning, "Possible code injection attack in: #{instruction}"
    end
    
  end
  
  class Model
    attr_reader :id, :parent_id, :model_name, :position, :possible_columns,
                :possible_associations, :joins
    attr_accessor :conditions, :fields, :join_type
    
    def initialize(parent_id, model_name, position, possible_columns = nil,
                   possible_associations = nil)
      @parent_id = parent_id                 
      @model_name = model_name
      @position = position
      @possible_columns = possible_columns if possible_columns
      @possible_associations = possible_associations if possible_associations
      
      @joins = []
      @conditions = []
      @fields = []
      
      generate_id!
    end
    
    def belongs_to?(related_model_name)
      return false if @possible_associations.nil?
      belongs_to_key = (@possible_associations["belongs_to"] ? "belongs_to" : :belongs_to)
      return false if @possible_associations[belongs_to_key].nil?
      
      related_model_name = related_model_name.underscore.singularize      
      @possible_associations[belongs_to_key].include? related_model_name
    end
    
    # Returns true if the model is root (has no parents).
    def is_root?; parent_id.nil?; end
    
    # Returns the table name
    def table_name; @model_name.tableize; end
    
    # Adds a new model as a join into the current model
    def add_join(model, join_type)
      model.join_type = join_type || DEFAULT_JOIN_TYPE
      @joins << model
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
  
  class Field
    attr_reader :column_name, :as_name
    
    def initialize(column_name, as_name)
      @column_name = column_name
      @as_name = as_name
    end
  end
  
  class Condition
    attr_reader :column_name, :operation, :value, :condition_type
    
    def initialize(column_name, operation, value, condition_type = nil)
      @column_name = column_name
      @operation = operation
      @value = value
      @condition_type = condition_type if condition_type
    end
    
  end
end
