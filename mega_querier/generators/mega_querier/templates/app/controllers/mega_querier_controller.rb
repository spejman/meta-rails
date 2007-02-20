require "mega_querier_rav"
include MegaQuerier
include MegaQuerierHelper

class MegaQuerierController < ApplicationController

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
  rav = MegaQuerier::RailsApplicationVisualizer.new({ :model_names => @activerecord_classes, :class_columns => @activerecord_columns,
                                                      :models => true, :controllers => false })
  rav.output("#{RAILS_ROOT}/public/images/pro-mq.png")
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
  if params[:join]
    params[:join].each do |key, value|
      next if value.blank?
      route = key.split("_")[1]
      route = route.split(",") if route
      route = [route] unless route.class == Array
      join_position = search_model_in_query(@actual_query, route)
      join_position[:join] << add_new_model_for_query(value)
    end
  end
  init
  render :partial => "make_query"
end

def add_new_model_for_query(model)
  {:model => model, :join => [] }
end

end
