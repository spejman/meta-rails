# Common libs and functionality for MetaQuerier controllers tools for doing 
# advanced queries to the tables of the application.
#
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

require "digest/md5"
require "fileutils"
require "meta_querier"
require "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/helpers/meta_querier_helper.rb"

include MetaQuerierHelper
include MetaRails::InferDbModel

if File.exists? META_QUERIER_HOOK_FILE
  if RAILS_ENV == "development"
    load META_QUERIER_HOOK_FILE
  else  
    require META_QUERIER_HOOK_FILE
  end
  include MetaQuerierHook
end

class MetaQuerierControllersCommon < ApplicationController
include MetaQuerierHook
  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/views/"
  
  layout "application", :except => ["run_query_txt", "run_query_excel"]

  
  # See inject_hook_code for more information about this around filter.
  around_filter do |controller, action_block|
    MetaQuerierControllersCommon.inject_hook_code(controller, action_block)
  end if File.exists? META_QUERIER_HOOK_FILE
  
  # ActAsAuthenticated hook. If ActAsAuthenticated is installed as a plugin
  # and MetaQuerierUseActAsAuth don't exists or its value is true then:
  #   - Includes AuthenticatedSystem
  #   - Calls login_required unless logged_in? before each request.
  if File.exists? "#{RAILS_ROOT}/vendor/plugins/acts_as_authenticated"
    include AuthenticatedSystem
    before_filter :do_login_if_required
    def do_login_if_required
      login_required if (!defined?(MetaQuerierUseActAsAuth) or MetaQuerierUseActAsAuth) and !logged_in?
    end
  end

  before_filter :load_avariable_profiles
  
  protected  
  def load_avariable_profiles
    session[:profile] ||= "ALL"
    session[:profile] = params[:profile] if params[:profile]

    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}    
  end

  # Inialization method
  #   - Checks if meta querier tables exists
  #   - Loads avariable profiles at @avariable_profiles
  #   - Creates @klasses_struct will all the profile related db data.
  #   - Fills @activerecord_classes, @activerecord_columns, @activerecord_associations global variables.
  def load_db_data
   
    raise "Meta querier tables don't exist, run script/generate meta_querier_query_tables, rake db:migrate \
    and restart the Server" unless META_QUERIER_TABLES

    if @avaliable_profiles.include? session[:profile]
      flash[:notice] = "Profile changed" if params[:profile]
      @klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
    else
      session[:profile] = "ALL"
      flash[:notice] = "Profile #{params[:profile]} doesn't exist using default profile #{session[:profile]}" if params[:profile]
      @klasses_struct = klass_struct
    end

    @activerecord_classes = @klasses_struct.keys
    @activerecord_columns = {}
    @klasses_struct.each {|klass_name, values| @activerecord_columns[klass_name] = (values["class_attr"] || {})}
    @activerecord_associations = {}
    @klasses_struct.each do |klass_name, values|
      @activerecord_associations[klass_name] = {}
      values["class_ass"].map{|e| e.to_a.flatten}.each {|rel| @activerecord_associations[klass_name][rel[1]] = rel[0]}
    end
    @actual_query = session[:actual_query]
    meta_querier_activerecord_associations_hook if defined?(meta_querier_activerecord_associations_hook) == "method"
  end
  
  # This function es called from an around filter that permits the execution of hook 
  # code before, after the execution of a controller action, or replacing the entire 
  # execution of the action.
  # 
  # A module called MetaQuerierHook with functions like #{controller_name}__#{action_name}_[replace, before, after]_hook
  # must be defined.
  # This file is typically located at META_QUERIER_HOOK_FILE
  # 
  # === Example
  # module MetaQuerierHook
  #   def meta_querier__edit_before_hook
  #     logger.debug "Executing code before calling the action edit on MetaQuerierController".
  #   end
  # end
  #
  def self.inject_hook_code(controller, action_block)
    controller_name = controller.params[:controller]
    action_name = controller.params[:action]
    prefix_function_names = "#{controller_name}__#{action_name}"
    
    if MetaQuerierHook.method_defined? "#{prefix_function_names}_replace_hook"       
      controller.send :"#{prefix_function_names}_replace_hook", controller.params
    else
      controller.send :"#{prefix_function_names}_before_hook", controller.params if MetaQuerierHook.method_defined? "#{prefix_function_names}_before_hook"
      action_block.call
      controller.send :"#{prefix_function_names}_after_hook", controller.params if MetaQuerierHook.method_defined? "#{prefix_function_names}_after_hook"
    end
  end

  
end
