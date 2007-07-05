module MetaQuerierHelper

  # NAVIGATION helpers

  
  # Returns the route of given key in query hash.
  # [[model_1, wide_1], ..., [model_n, wide_n]]
  def get_route(key)
    route = key.split("__").collect {|e| [e.split("_")[0], e.split("_")[1].to_i] }
    return route
  end

  # Returns the node with the model in the query hash for given key.
  def search_model_in_query(query, route)
    route ||= []
    return query.select {|aq| aq[:model] == route[0][0] &&  aq[:wide] == route[0][1]}[0] if route.size == 1
    actual_node = route.shift  
    search_model_in_query(query.select {|aq| aq[:model] == actual_node[0] &&  aq[:wide] == actual_node[1] }[0][:join], route)
  end

  # Gives a block of |node, route| for given query.
  def each_model_with_route(query, model = "", &block)
    query.each do |actual_q|
        route = (model + "__" unless model.blank?) || ""
        route += "#{actual_q[:model]}_#{actual_q[:wide]}"
        yield actual_q, route rescue raise route
        each_model_with_route(actual_q[:join], route, &block) if actual_q[:join]
    end    
  end
  
  # Returns an Array with all the conditions of the query with its indexes:
  # [condition, position, route]
  def get_conditions(query)
    conditions = []
    each_model_with_route(query) do |node, route|
      node[:conditions].each_with_index {|c, i| conditions << {:cond => c, :position => i, :route => route}} unless node[:conditions].empty?
    end
    return conditions
  end
  
  # Search the model in the query and deletes it
  def delete_model_in_query(query, route)
    route ||= []
    # final case of recursive search
    return query.delete_if {|aq| aq[:model] == route[0][0] &&  aq[:wide] == route[0][1] } if route.size == 1

    # recursive search
    actual_node = route.shift  
    delete_model_in_query(query.select {|aq| aq[:model] == actual_node[0] &&  aq[:wide] == actual_node[1] }[0][:join], route)
  end
  
  # CREATE SQL Helpers
  
  # Returns a string to use for create the select fields of the sql query
  def get_fields_for_select(query, columns, key = "t_")
    fields = []
    logger.debug query.to_json
    
    query.each_with_index do |query_n, q_index|
      key_tmp = key
      key_tmp += "__" unless key_tmp == "t_"
      key_tmp += "#{query_n[:model]}_#{query_n[:wide]}"
    #logger.debug "query_n --> #{query_n.to_json}"
      query_n[:select].each do |field, value|
        fields << "#{key_tmp}.#{field} as #{key_tmp}___#{field}".to_sym if value
      end unless query_n[:select].empty?
      fields << get_fields_for_select(query_n[:join], columns, key_tmp) unless query_n[:join].empty?
    end

    fields.flatten
  end

  # Returns the SQL corresponding to the query
  def get_sql_for_query(actual_query, columns)
  #  st = Select["t_0.name".to_sym, "t_0_0.name as name2".to_sym]
    return "" if actual_query.nil? or actual_query.empty?
    logger.debug "get_sql_for_query 0"
    fields = get_fields_for_select(actual_query, columns)
    st = Select[fields]
    
    tables = []
    #actual_query.each_with_index do |query, q_index|
      key = "t_#{actual_query[0][:model]}_#{actual_query[0][:wide]}"
      tables << actual_query[0][:model].tableize.to_sym.as(key.to_sym)   
      columns[actual_query[0][:model]].each do |field|
        fields << "#{key}.#{field[0]} as #{key}___#{field[0]}".to_sym
      end
    #end

    st.from[tables]
    add_inner_joins_to_sql_for_query(actual_query[0], key, st)
    add_where_to_sql_for_query(actual_query[0], key, st, true)
    st.to_sql
  end
  
  # Adds inner joins to the SQL query
  def add_inner_joins_to_sql_for_query(query, key, st)
    logger.debug "add_inner_joins_to_sql_for_query 0 - #{key}"
    return if query[:join].empty?
    logger.debug "add_inner_joins_to_sql_for_query 1 - #{key}"

    tables = {:inner => [], :left => [], :right => []}
    query[:join].each do |query_n|
      key_tmp = key; key_tmp += "__" unless key_tmp.blank?
      key_tmp += "#{query_n[:model]}_#{query_n[:wide]}"
      tables[query_n[:join_type].to_sym] << [query_n[:model], key_tmp, query_n[:model].tableize.to_sym.as(key_tmp.to_sym)]   
    end
    
    logger.debug tables.to_json
    [:inner, :right, :left].each do |join_type|
      unless tables[join_type].empty?

        tables[join_type].each do |join_table|
          if ((@activerecord_associations[query[:model]].keys.include? "#{join_table[0].singularize.underscore}") \
                && (@activerecord_associations[query[:model]]["#{join_table[0].singularize.underscore}"] == "belongs_to")) \
              || ((@activerecord_associations[join_table[0].classify].keys.include? query[:model].singularize.underscore) \
                && (@activerecord_associations[join_table[0].classify][query[:model].singularize.underscore] != "belongs_to"))               
            left_prefix = "#{join_table[0].singularize.underscore}_id"; right_prefix = "id"
          else
            left_prefix = "id"; right_prefix = "#{query[:model].singularize.underscore}_id"
          end
          
          st.send("#{join_type}_join")[join_table[2]].on { eval "#{key}.#{left_prefix} == #{join_table[1]}.#{right_prefix}" }
        end
        
      end     
    end

    query[:join].each do |query_n|
      key_tmp = key; key_tmp += "__" unless key_tmp.blank?
      key_tmp += "#{query_n[:model]}_#{query_n[:wide]}"
      add_inner_joins_to_sql_for_query(query_n, key_tmp, st)
    end
    
  end
  
  # Adds where clauses to the SQL query
  def add_where_to_sql_for_query(query, key, st, is_first = false)
      unless query[:conditions].empty?
        cond = query[:conditions].dup
        or_conds = cond.select { |c| c[:cond_type] == "OR" }.sort_by { |c| cond.index c }
    
          conds_grouped_by_ors = []
          or_conds.each do |or_cond|
            conds_grouped_by_ors << cond.slice!(0..(cond.index(or_cond)-1))
          end
          conds_grouped_by_ors << cond
    
    
        logger.debug conds_grouped_by_ors.to_json
        
        str_cond = conds_grouped_by_ors[0].collect { |cond| "#{key}.#{cond[:column]} #{cond[:op]} #{cond[:value]}" }
        if is_first
          st.where { eval str_cond.join(";") }
          is_first = false
        else
          st.and { eval str_cond.join(";") }
        end
        conds_grouped_by_ors[1..-1].each do |cond_grouped|
          str_cond = cond_grouped.collect { |cond| "#{key}.#{cond[:column]} #{cond[:op]} #{cond[:value]}" }
          st.or { eval str_cond.join(";") }    
        end  
    end
    return is_first if query[:join].empty?

    # Actualize is_first to know if is the first condition or
    # not. This is necessary in order to put AND to the sql query.
    is_first = is_first && query[:conditions].empty?
    query[:join].each_with_index do |query_n, q_index|
      key_tmp = key; key_tmp += "__" unless key_tmp.blank?
      key_tmp += "#{query_n[:model]}_#{query_n[:wide]}"    
      is_first = add_where_to_sql_for_query(query_n, key_tmp, st, is_first)
#      is_first = is_first && query_n[:conditions].empty?
    end    
    return is_first
  end

  # STRUCTURE helpers 
  def add_new_model_for_query(model, select, deep, wide, join_type = nil, join = [], conditions = [])
    {:model => model, :select => select, :deep => deep, :wide => wide, :join_type => join_type, :join => join, :conditions => conditions }
  end
  
  def add_new_condition_for_query(column_name, op, value, cond_type = nil)
    { :column => column_name,
      :op => op,
      :value => value,
      :cond_type => cond_type 
    }
  end
  
  def add_columns_select_for_query(columns_hash)
    hash = {}
    columns_hash.each { |k| hash[k] = true}
    hash
  end
  
  # VIEWS helpers
  def model_name(model_route)
    #model_route.collect {|mr| mr.split("_")[0]}.join(".")
    model_route.join(".")
  end

  def model_condition_html(ac)
    str = ("<b>#{ac[:cond_type]}</b> " if ac[:cond_type]) || ""
    str += "#{ac[:column]} #{ac[:op]} #{ac[:value]}"
    return str
  end

  def adecuate_conditions_value(conditions_value, conditions_op, column_type)
    conditions_value = "%" + conditions_value + "%" if conditions_op == "=~"
    conditions_value = "\"" + conditions_value + "\"" if column_type == "string"
    conditions_value
  end

end
