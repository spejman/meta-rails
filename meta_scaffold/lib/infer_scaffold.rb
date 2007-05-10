##
##
## THIS IS A TEST, DON'T WORK AS EXPECTED!!!
##


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

def infere_scaffold

  get_activerecord_classes(get_table_names).each do |class_name|
    controller_code = "class Inferred#{class_name.camelize.pluralize}Controller < ActionController::Base \n \
                          self.template_root = RAILS_ROOT + \"/vendor/plugins/meta_querier/app/views/\" \n \
                          layout \"meta_scaffold\" \n \
  	                      #active_scaffold :#{class_name.underscore.singularize} \n \
  	                      def index; render :text => \"vaa\"; end \n \
                       end"
    #puts controller_code
    #eval controller_code
    #ActionController::Routing::Routes.add_route("/inferred_#{class_name.underscore.pluralize}/:action", {:controller => "inferred_#{class_name.underscore.pluralize}"})
  end if false
  #p Module.constants.select {|c| c.include? "Controller"}
  load_infer_controller

end

def load_infer_controller

  directory = "#{RAILS_ROOT}/vendor/plugins/meta_scaffold"
  
  controller_path = File.join(directory, 'lib')
  #require "#{controller_path}/infer_controller.rb"
  $LOAD_PATH << controller_path
  if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION >= '1.2.0'
    Dependencies.load_paths << controller_path
  else
    raise "Engines plugin is needed for running meta_querier with a Ruby on Rails version < 1.2.0" if Dir["#{RAILS_ROOT}/vendor/plugins/engines"].empty?
  end

  Rails::Initializer.run do |config|
    config.controller_paths << controller_path
  end
end