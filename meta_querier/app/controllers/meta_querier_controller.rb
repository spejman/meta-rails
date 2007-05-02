require "meta_querier"
require "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/helpers/meta_querier_helper.rb"

include MetaQuerier
include MetaQuerierHelper

class MetaQuerierController < ActionController::Base

  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/views/"
  
  layout "application"
  
  AR_DB_RESERVED_WORDS = ["schema_info", "engine_schema_info"]
  AR_DB_NO_RELEVANT_COLUMNS = ["id"]
  
  def init
    @tables = get_table_names
    @activerecord_classes = get_activerecord_classes(@tables)
  
    @activerecord_columns = {}
    @activerecord_classes.each {|ar_class_name| AR_DB_NO_RELEVANT_COLUMNS << ar_class_name.underscore + "_id"}
    @activerecord_classes.each {|ar_class_name| @activerecord_columns[ar_class_name] = get_activerecord_attributes(ar_class_name)}
  
    @activerecord_associations = {}
    @activerecord_classes.each {|ar_class_name| @activerecord_associations[ar_class_name] = get_activerecord_associations(ar_class_name)}
  end
  
  def index
    init
    @actual_query = session[:actual_query]
    @q_sql = get_sql_for_query(@actual_query) if session[:actual_query]
  end
  
  def get_image
    init
    @actual_query = session[:actual_query]
    @q_sql = get_sql_for_query(@actual_query) if session[:actual_query]
    
    rav = MetaQuerier::RailsApplicationVisualizer.new({ :model_names => @activerecord_classes, :class_columns => @activerecord_columns,
                                                        :models => true, :controllers => false })
    rav.output("#{RAILS_ROOT}/public/images/pro-mq.png")
    redirect_to "/images/pro-mq.png"
  end
  
  def get_table_names
   # Only tested with MySql. The db must accept "SHOW TABLES" SQL sentence.
   table_names_hash = ActiveRecord::Base.connection.select_values("SHOW TABLES") - AR_DB_RESERVED_WORDS
  end
  
  def get_activerecord_classes(table_names)
    activerecord_classes_names = []
    table_names.each do |table_name|
      table_name = table_name.classify
      begin # if table_name couldn't be a constant .constantize will throw a exception.
        activerecord_classes_names << table_name if table_name.constantize
      rescue; end
    end
    activerecord_classes_names
  end
  
  
  def get_activerecord_attributes(ar_class_name)
    columns = {}
    ActiveRecord::Base.connection.columns(ar_class_name.tableize).each {|c| 
        columns[c.name] = c.type unless AR_DB_NO_RELEVANT_COLUMNS.include?(c.name)  }
    columns
  end
  
  def get_activerecord_associations(ar_class_name)
    associations = {}
    ar_class_name.constantize.reflections.each do |a_name, a_values|
      associations[a_name] = a_values.macro.to_s
    end
    associations
  end
  
  def clear_query
    session[:actual_query] = nil
    init
    render :partial => "make_query"
  end
  
  def make_query
    session[:actual_query] ||= []
    @actual_query = session[:actual_query]
    if params[:query] 
      @actual_query << add_new_model_for_query(params[:query][:model]) if params[:query][:model]
    end
    # Get join conditions
    if params[:join]
      params[:join].each do |key, value|
        next if value.blank?
        route = get_route(key)
        join_position = search_model_in_query(@actual_query, route)
        join_position[:join] << add_new_model_for_query(value)
      end
    end
  
    # Get conditions for each model
    if params[:conditions_column] and  params[:conditions_op] and params[:conditions_value]
      params[:conditions_column].each do |key, column_name|
        # jump to next if op and value fields are empty
        # TODO: show a message warning: ej. not op field choosen ...
        next if column_name.blank? or !params[:conditions_op][key] or !params[:conditions_value][key]
        next if params[:conditions_op][key].blank? or params[:conditions_value][key].blank?
        route = get_route(key)
        join_position = search_model_in_query(@actual_query, route)
  
        # jump if there're more than one condition but there aren't any condition type (or, and, ... )
        # TODO: show a message warning
        #raise "aqui" if !join_position[:conditions].empty? and (!params[:conditions_cond_type][key] or params[:conditions_cond_type][key].blank?)
  
        # add the condition
        params_type = params[:conditions_cond_type][key] if params[:conditions_cond_type]
        join_position[:conditions] << add_new_condition_for_query(column_name, params[:conditions_op][key],
                                          params[:conditions_value][key],  params_type)
      end
    end
    @q_sql = get_sql_for_query(@actual_query)
    init
    render :partial => "make_query"
  end
  
  def run_query
    @actual_query = session[:actual_query]
    if @actual_query
      @ar_base = ActiveRecord::Base.connection.select_all(get_sql_for_query(@actual_query))
    end
    render :partial => "run_query"
  end
  
  def remove_condition
    @actual_query = session[:actual_query]
    route = get_route(params[:condition_model])
    cond_position = search_model_in_query(@actual_query, route)
    cond_position[:conditions].delete_at(params[:condition_index].to_i)
    cond_position[:conditions][0][:cond_type] = nil unless cond_position[:conditions].empty?
    @q_sql = get_sql_for_query(@actual_query)
    init
    render :partial => "make_query"
#    render :text => join_position.to_json
  end
  
  def get_route(key)
    route = key.split("_")[1]
    route = route.split(",") if route
    route = [route] unless route.class == Array
    return route
  end
  
  def add_new_model_for_query(model)
    {:model => model, :join => [], :conditions => [] }
  end
  
  def add_new_condition_for_query(column_name, op, value, cond_type = nil)
    { :column => column_name,
      :op => op,
      :value => value,
      :cond_type => cond_type 
    }
  end
  
  def get_sql_for_query(actual_query)
  #  st = Select["t_0.name".to_sym, "t_0_0.name as name2".to_sym]
    st = Select.all
    logger.debug "get_sql_for_query 0"
    tables = []
    actual_query.each_with_index do |query, q_index|
      tables << query[:model].tableize.to_sym.as("t_#{q_index}".to_sym)   
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
    query[:join].each_with_index do |query_n, q_index|
      add_where_to_sql_for_query(query_n, "#{parent_index}_#{q_index}", st)
    end    
      
  end

end
