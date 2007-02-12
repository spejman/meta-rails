require "mega_querier_rav"
include MegaQuerier

class MegaQuerierController < ApplicationController

def index
  @tables = get_table_names
  @activerecord_classes = get_activerecord_classes(@tables)

  @activerecord_columns = {}
  @activerecord_classes.each {|ar_class_name| @activerecord_columns[ar_class_name] = get_activerecord_attributes(ar_class_name)}

  @activerecord_associations = {}
  @activerecord_classes.each {|ar_class_name| @activerecord_associations[ar_class_name] = get_activerecord_associations(ar_class_name)}

  rav = MegaQuerier::RailsApplicationVisualizer.new({ :model_names => @activerecord_classes, :class_columns => @activerecord_columns,
                                                      :models => true, :controllers => false })
  rav.output("#{RAILS_ROOT}/public/images/pro-mq.png")
end


AR_DB_RESERVED_WORDS = ["schema_info", "engine_schema_info"]

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

AR_DB_NO_RELEVANT_COLUMNS = ["id", "created_on"]
def get_activerecord_attributes(ar_class_name)
  columns = ActiveRecord::Base.connection.columns(ar_class_name.tableize).collect {|c| c.name } - AR_DB_NO_RELEVANT_COLUMNS
end

def get_activerecord_associations(ar_class_name)
  associations = {}
  eval(ar_class_name).reflections.each do |a_name, a_values|
    associations[a_name] = a_values.macro.to_s
  end
  associations
end

end
