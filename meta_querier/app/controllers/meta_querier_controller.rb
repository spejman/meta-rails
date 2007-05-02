require "meta_querier"
require "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/helpers/meta_querier_helper.rb"

include MetaQuerier
include MetaQuerierHelper

class MetaQuerierController < ActionController::Base

  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/views/"
  
  layout "application"
  
  AR_DB_RESERVED_WORDS = ["schema_info", "engine_schema_info"]
  AR_DB_NO_RELEVANT_COLUMNS = ["id"]

# INIT methods
# 
  
  def init
    @tables = get_table_names
    @activerecord_classes = get_activerecord_classes(@tables)
  
    @activerecord_columns = {}
    @activerecord_classes.each {|ar_class_name| AR_DB_NO_RELEVANT_COLUMNS << ar_class_name.underscore + "_id"}
    @activerecord_classes.each {|ar_class_name| @activerecord_columns[ar_class_name] = get_activerecord_attributes(ar_class_name)}
  
    @activerecord_associations = {}
    @activerecord_classes.each {|ar_class_name| @activerecord_associations[ar_class_name] = get_activerecord_associations(ar_class_name)}
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

# ACTIONS
# 

  def index
    init
    @actual_query = session[:actual_query]
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns) if session[:actual_query]
  end
  
  def get_image
    init
    @actual_query = session[:actual_query]
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns) if session[:actual_query]
    
    rav = MetaQuerier::RailsApplicationVisualizer.new({ :model_names => @activerecord_classes, :class_columns => @activerecord_columns,
                                                        :models => true, :controllers => false })
    rav.output("#{RAILS_ROOT}/public/images/pro-mq.png")
    redirect_to "/images/pro-mq.png"
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
    init
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"
  end
  
  def run_query
    init
    @actual_query = session[:actual_query]
    if @actual_query
      @ar_base = ActiveRecord::Base.connection.select_all(get_sql_for_query(@actual_query, @activerecord_columns))
    end
    render :partial => "run_query"
  end
  
  def remove_condition
    @actual_query = session[:actual_query]
    route = get_route(params[:condition_model])
    cond_position = search_model_in_query(@actual_query, route)
    cond_position[:conditions].delete_at(params[:condition_index].to_i)
    cond_position[:conditions][0][:cond_type] = nil unless cond_position[:conditions].empty?
    init
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"
#    render :text => join_position.to_json
  end

end
