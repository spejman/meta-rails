module MetaQuerierHelper

  # Returns the route of given key in query hash.
  def get_route(key)
    route = key.split("_")[1]
    route = route.split(",") if route
    route = [route] unless route.class == Array
    return route
  end

  # Returns the node with the model in the query hash for given key.
  def search_model_in_query(query, route)
    route ||= []
    return query.select {|aq| aq[:model] == route[0] }[0] if route.size == 1
    actual_node = route.shift  
    search_model_in_query(query.select {|aq| aq[:model] == actual_node }[0][:join], route)
  end

  def delete_model_in_query(query, route)
    route ||= []
    # final case of recursive search
    return query.delete_if {|aq| aq[:model] == route[0] } if route.size == 1

    # recursive search
    actual_node = route.shift  
    delete_model_in_query(query.select {|aq| aq[:model] == actual_node }[0][:join], route)
  end
  
  def add_new_model_for_query(model, join = [], conditions = [])
    {:model => model, :join => join, :conditions => conditions }
  end
  
  def add_new_condition_for_query(column_name, op, value, cond_type = nil)
    { :column => column_name,
      :op => op,
      :value => value,
      :cond_type => cond_type 
    }
  end
  
  def get_fields_for_select(query, columns, parent_index = "")
    fields = []
    logger.debug query.to_json
    query.each_with_index do |query_n, q_index|
    #logger.debug "query_n --> #{query_n.to_json}"
      columns[query_n[:model]].each do |field|
        fields << "t#{parent_index}_#{q_index}.#{field[0]} as t#{parent_index}_#{q_index}__#{field[0]}".to_sym
      end
      fields << get_fields_for_select(query_n[:join], columns, "#{parent_index}_#{q_index}") unless query_n[:join].empty?
    end

    fields.flatten
  end
  
  def get_sql_for_query(actual_query, columns)
  #  st = Select["t_0.name".to_sym, "t_0_0.name as name2".to_sym]
    return "" if actual_query.nil? or actual_query.empty?
    logger.debug "get_sql_for_query 0"
    fields = get_fields_for_select(actual_query, columns)
    st = Select[fields]
    
    tables = []
    actual_query.each_with_index do |query, q_index|
      tables << query[:model].tableize.to_sym.as("t_#{q_index}".to_sym)   
      columns[query[:model]].each do |field|
        fields << "t_#{q_index}.#{field[0]} as t_#{q_index}__#{field[0]}".to_sym
      end
    end

    st.from[tables]
    add_inner_joins_to_sql_for_query(actual_query[0], 0, st)
    add_where_to_sql_for_query(actual_query[0], 0, st, true)
    st.to_sql
  end
  
  def add_inner_joins_to_sql_for_query(query, parent_index, st)
    logger.debug "add_inner_joins_to_sql_for_query 0 - #{parent_index}"
    return if query[:join].empty?
    logger.debug "add_inner_joins_to_sql_for_query 1 - #{parent_index}"
    tables = []
    query[:join].each_with_index do |query_n, q_index|
      tables << query_n[:model].tableize  .to_sym.as("t_#{parent_index}_#{q_index}".to_sym)   
    end
    logger.debug tables.to_json
    st.inner_join[tables]
    query[:join].each_with_index do |query_n, q_index|
      add_inner_joins_to_sql_for_query(query_n, "#{parent_index}_#{q_index}", st)
    end
    
  end
  
  
  def add_where_to_sql_for_query(query, parent_index, st, is_first = false)
      unless query[:conditions].empty?
        cond = query[:conditions].dup
        or_conds = cond.select { |c| c[:cond_type] == "OR" }.sort_by { |c| cond.index c }
    
          conds_grouped_by_ors = []
          or_conds.each do |or_cond|
            conds_grouped_by_ors << cond.slice!(0..(cond.index(or_cond)-1))
          end
          conds_grouped_by_ors << cond
    
    
        logger.debug conds_grouped_by_ors.to_json
        
        str_cond = conds_grouped_by_ors[0].collect { |cond| "t_#{parent_index}.#{cond[:column]} #{cond[:op]} #{cond[:value]}" }
        if is_first
          st.where { eval str_cond.join(";") }
        else
          st.and { eval str_cond.join(";") }
        end
        conds_grouped_by_ors[1..-1].each do |cond_grouped|
          str_cond = cond_grouped.collect { |cond| "t_#{parent_index}.#{cond[:column]} #{cond[:op]} #{cond[:value]}" }
          st.or { eval str_cond.join(";") }    
        end  
    end
    return if query[:join].empty?

    # Actualize is_first to know if is the first condition or
    # not. This is necessary in order to put AND to the sql query.
    is_first = is_first && query[:conditions].empty?
    query[:join].each_with_index do |query_n, q_index|      
      add_where_to_sql_for_query(query_n, "#{parent_index}_#{q_index}", st, is_first)
      is_first = is_first && query_n[:conditions].empty?
    end    
      
  end


end
