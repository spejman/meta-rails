module MetaQuery

  class Query
    
    attr_reader :root, :order_by, :fields
    
    def initialize
      @root = []
      @models_by_key = {}
      @order_by = []
      @fields = []
    end
        
    def dump
      Marshal.dump(self)
    end
    
    def load(dump_string)
      Marshal.load(dump_string)
    end
    
    # True if the query has the minimum values in order to be runnable.
    def runnable?
      !self.models.empty? && !self.fields.empty?
    end
    
    # Adds a model to the query, creates the join between the new model and
    # the parent model. Finally, returns the new model object.
    # In order to generate the sql, possible_columns and possible_associations must be
    # given like:
    # possible_columns =  {"label" => "string", "name" => "string", "order" => "integer"}
    # possible_associations = {:has_many => ["lexical_entries", ..., "senses"], :belongs_to => ["lexicon", ..., "lexical_resource"]}
    def add_model(parent_id, model_name, position, possible_columns = nil, possible_associations = nil, join_type = nil, hidden = false)
      new_model = Model.new parent_id, model_name, position, possible_columns, possible_associations, hidden
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
    def add_condition(model_id, column_name, operation, value, condition_type = nil, parametrizable = false)
      model = get_model model_id
      model.add_condition(column_name, operation, value, condition_type, parametrizable)
    end
        
    # Adds a field to the model, returns the created field.
    def add_field(model_id, column_name, as_name, field_type = nil)
      each_model do |model|
        raise "A field with \"#{as_name}\" name already exists at \"#{model.name}\" \
              model" if model.fields.any? {|f| f.as_name == as_name}
      end
      model = get_model model_id
      @fields << model.add_field(column_name, as_name, field_type)
    end

    def add_order_by(field_key, direction = "asc")
      @order_by << [field_key, direction]
    end

    def remove_order_by(order_by_index)
      @order_by.delete_at order_by_index
    end
    
    def get_field(field_key)
      each_model do |model|
        model.fields.each do |field|
          return field if field.as_name == field_key
        end
      end
      nil
    end
    
    # Sets a parametrized condition value, raises QueryException if the condition
    # is not parametrizable.
    def set_parametrized_condition_value(model_id, condition_index, value)
      model = get_model model_id
      model.set_parametrized_condition_value(condition_index, value)
    end
    
    # Removes the model and all its children!!! and associated data (conditions,
    # fields) from the query and from the joins of its parents.
    def remove_model(model_id)
      model_id = model_id.id if model_id.class == MetaQuery::Model
      model_to_remove = get_model(model_id)
      raise "Model with model_id #{model_id} doesn't exist" if model_to_remove.nil?
      
      removed_models = [model_to_remove]
      
      # remove model joins (we must copy the joins list because remove_model changes
      # the join list and then the "each" don't go though all the join models)
      joins = model_to_remove.joins.dup
      joins.each {|j| removed_models += remove_model j; join_size -= 1 }
      
      # remove its fields
      model_to_remove.fields.each {|f| @fields.delete f}
      # remove its order by fields     
      model_to_remove.fields.each {|f| @order_by.delete_if {|ob| ob[0] == f.as_name} }
      # remove itself
      @models_by_key.delete(model_id)
      
      # if the model has parents remove it from its join list.
      parent = get_model(model_to_remove.parent_id) 
      parent.joins.delete model_to_remove if parent
      
      # if the model is root remove it form the root array
      @root.delete model_to_remove if model_to_remove.is_root?
      return removed_models
    end
    
    # Removes the condition with given index from the given model. Returns the
    # removed condition.
    def remove_condition(model_id, condition_index)
      model = get_model model_id
      model.remove_condition condition_index
    end

    # Removes the field with given index from the given model. Returns the
    # removed field.
    def remove_field(model_id, field_index)
      model = get_model model_id
      @fields.delete model.remove_field(field_index)
    end

    
    # Go through all the models of the query (unordered).
    def each_model
      models.each do |model|
        yield(model)
      end
    end
    
    # Returns a array with all the models
    def models
      @models_by_key.values.sort_by {|m| m.id.split("_")[-1]}
    end
    
    # Returns the model identified by model_id
    def get_model(model_id)
      return @models_by_key[model_id]
    end
    
    # Returns a array with all the root models tables names and its identifiers in this form:
    # [ [ table_name_1, table_id_1 ], ..., [ table_name_N, table_id_N ] ]
    def all_from_tables
      from_tables = []; @root.each do |root_model|
        from_tables << [root_model.table_name, root_model.id]
      end
      from_tables
    end

    
    # GENERATE SQL related functions
    # 
   
    # Returns the SQL sentence for the query
    def to_sql
      fields = all_fields_sql.collect {|field| field.to_sym }
      st = Select[fields]
      
      from_tables = all_from_tables.collect {|table| table[0].to_sym.as table[1].to_sym}
      st.from[from_tables]
      
      joins = all_joins_sql#.sort_by {|j| j[1].to_s.size} # order by key size bigger key --> deeper in the query ...
#      raise all_joins_sql.to_json
      joins.each do |join_def|
        st.left_join[join_def[1]]
       # st.send(:"#{join_def[0].gsub(" ", "_")}")[join_def[1]]
       # raise join_def[2]
        st.on { eval join_def[2] }
      end
      
      conditions = all_sql_conditions
      unless conditions.empty?
        st.where { eval conditions.shift[1] }
        conditions.each do |cond|
          if cond[0] == "AND"
            begin
              st.and { eval cond[1] }
            rescue 
              raise QueryException, "Condition value \"#{cond[1]}\" invalid."
            end
          elsif cond[0] == "OR"
            begin
              st.or { eval cond[1] }
            rescue 
              raise QueryException, "Condition value \"#{cond[1]}\" invalid."
            end
          else
            raise QueryException, "Condition \"#{cond[0]}\" not supported."
          end
        end
      end
      
      sql = st.to_sql
      
      if @order_by && !@order_by.empty?
        sql += " ORDER BY " + @order_by.collect {|ob| "\"#{ob[0].gsub(".", "_")}\" #{ob[1]}"}.join(", ")
      end
      
      return sql
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

    # Returns a array with all the fields and its "as" values in this form:
    # [ "model_id.field_name_1 as field_as_1" , ..., "model_id.field_name_N as field_as_N" ]
    def all_fields_sql
      fields.collect {|f| f.to_sql }
    end
        
    def all_joins_sql      
      joins = []; each_model do |model|
        model.joins.each do |join_model|
          if !model.belongs_to?(join_model.model_name) && !join_model.belongs_to?(model.model_name)
            # CASE habtm because any model belongs to the other.
            habtm_join_table = [join_model.table_name, model.table_name].sort.join "_"
            habtm_join_id = model.id + join_model.id
            join_type = join_model.join_type #TODO: think if is the correct join type
            join_table = habtm_join_table.to_sym.as(habtm_join_id.to_sym)
            join_condition = "#{model.id}.id == #{habtm_join_id}.#{model.model_name.underscore}_id"
            join_condition += " and #{join_model.conditions.collect {|cond| cond.to_sql }.join(" and ")}" unless join_model.conditions.empty?
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
            
            join_condition = "#{model.id}." + (model.belongs_to?(join_model.model_name) ? "#{join_model.model_name.underscore.singularize}_id" : "id") \
              + " == #{join_model.id}." + (join_model.belongs_to?(model.model_name) ? "#{model.model_name.underscore.singularize}_id" : "id")
            join_condition += " and #{join_model.conditions.collect {|cond| cond.to_sql }.join(" and ")}" if join_model.hidden && !join_model.conditions.empty?
            #dc_conditions = model.conditions.select {|cond| cond.is_data_category? }

            check_for_code_injection(join_condition)
            joins << [join_type, join_table, join_condition]
          end
        end     
      end  
      joins
    end
    
    def all_sql_conditions
      conditions = []; each_model do |model|
        next if model.hidden
        model.conditions.each do |cond|
          cond_declaration = cond.to_sql
          check_for_code_injection(cond_declaration)
          conditions << [cond.condition_type || DEFAULT_CODITION, cond_declaration]
        end
      end
      conditions
    end
    
  end
  
  
end