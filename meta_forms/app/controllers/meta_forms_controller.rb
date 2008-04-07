# Ruby on Rails Controller that loads itself at /meta_querier url
# of the application.
# 
# Provides tools for doing advanced queries to the tables of the application.
#
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

require "digest/md5"
require "fileutils"
require "meta_forms"
require "#{RAILS_ROOT}/vendor/plugins/meta_forms/app/helpers/meta_forms_helper.rb"

require "meta_rails_common"
include MetaRails


include MetaFormsHelper
include MetaRails::InferDbModel

# Ruby on Rails Controller that loads itself at /meta_forms url
# of the application.
# 
# Provides tools for creating custom forms for later use.

class MetaFormsController < ApplicationController
  helper "data_categories_browser"
  
  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_forms/app/views/"
  
  layout select_layout("meta_forms")

  # ActAsAuthenticated hook. If ActAsAuthenticated is installed as a plugin
  # and MetaQuerierUseActAsAuth don't exists or its value is true then:
  #   - Includes AuthenticatedSystem
  #   - Calls login_required unless logged_in? before each request.
  if File.exists? "#{RAILS_ROOT}/vendor/plugins/acts_as_authenticated"
    include AuthenticatedSystem
    before_filter :do_login_if_required
    def do_login_if_required
      login_required if (!defined?(MetaFormsUseActAsAuth) or MetaFormsUseActAsAuth) and !logged_in?
    end
  end
  
  before_filter :init, :only => ["edit", "add_form_table", "add_related_form_table", "add_removed_attr_to_form_table"]
  
  
  # Inialization method
  #   - Checks if meta querier tables exists
  #   - Loads avariable profiles at @avariable_profiles
  #   - Creates @klasses_struct will all the profile related db data.
  #   - Fills @activerecord_classes, @activerecord_columns, @activerecord_associations global variables.
  def init  
    raise "Meta forms tables don't exist, run script/generate meta_querier_query_tables, rake db:migrate \
    and restart the Server" unless META_FORMS_TABLES
    
    set_current_profile("ALL",true) 

  end  

  def index
    redirect_to :action => :list
  end
  
  def set_current_profile(profile,force_reload_klasses=false)
    
    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}

    if @avaliable_profiles.include? profile
      flash[:notice] = "Profile changed" if profile
      @klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{profile}.yml").read)
    else
      session[:profile] = "ALL"
      flash[:notice] = "Profile #{params[:profile]} doesn't exist using default profile #{session[:profile]}" if params[:profile]
      @klasses_struct = klass_struct
    end
    
    return if profile == self.current_profile && !force_reload_klasses
    session[:profile] = profile 
    
    @activerecord_classes = @klasses_struct.keys
    @activerecord_columns = {}
    @klasses_struct.each {|klass_name, values| @activerecord_columns[klass_name] = (values["class_attr"] || {})}
    @activerecord_associations = {}
    @klasses_struct.each do |klass_name, values|
      @activerecord_associations[klass_name] = {}
      values["class_ass"].map{|e| e.to_a.flatten}.each {|rel| @activerecord_associations[klass_name][rel[1]] = rel[0]}
    end
  end
  
  def current_profile
    session[:profile]
  end

  def edit
    @form_form_url = url_for :action => :create_form
    @form_form_submit_text = "Create form"
    @new_form = params[:new_form]
    if params[:id]
      @form = MetaFormsForm.find params[:id]
        set_current_profile(@form.profile) unless @new_form
      @form_form_url = url_for :action => :update_form
      @form_form_submit_text = "Update form"
    end
     
  end
  
  def list
    @forms = MetaFormsForm.find :all
    #raise "q te lo crees"
  end
  
  def execute
    if params[:id]
      @form = MetaFormsForm.find params[:id]
      @last_call_params = params[:last_call_params]
    end
  end

  # Execute forms
  
  def save_form_data
    
    objects = []
    redirect_to :action => :execute, :id => params[:form_id], :last_call_params => params
    
    flash[:notice] = save_data_create_objects(objects)
    return if !flash[:notice].empty?
    
    flash[:notice] = save_data_create_object_associations(objects)
       
  end
  
  #create objects from parameters (without associations yet)
  def save_data_create_objects(objects=[])
    
    params[:new_objects].each do |key, val| 
      #objects[key.to_i] =val.keys[0].constantize.new(val.values[0])
      objects[key.to_i] = if val.values[0][:id] && !val.values[0][:id].blank?
        # Find in the database the default object selected.
        val.keys[0].constantize.find val.values[0][:id].to_i
      else
        # Create a new object.
        val.keys[0].constantize.create
      end
      
      form_table = MetaFormsFormTable.find(params[:form_tables_by_index][key])
      
      form_table.table_attributes.each do |attr|
        value = val.values[0][attr.attr_name.to_sym]
        if attr.compulsory? && attr.field_type != 'boolean'
          return "[#{form_table.name} - #{attr.name || attr.attr_name}] can't be blank" if value.nil? || value.blank?
        end        
        if attr.field_type == 'boolean' || attr.field_type == 'string' || attr.field_type == 'integer' || attr.field_type == 'text'
          objects[key.to_i].send(:"#{attr.attr_name}=", value)
        elsif attr.field_type == 'data_category'
          dc = DataCategory.find attr.attr_name
          objects[key.to_i].add_feat(dc, value)
        else
          raise "Field type: #{attr.field_type} not supported"
        end
      end unless form_table.default_id_value
      
    end
    
    objects.each do |obj| 
      if !obj.valid?
        return obj.errors.full_messages[0]
      end
    end
    
    objects.each do |obj| 
      if !obj.save 
        return obj.errors.full_messages[0]
      end
    end
    ""
  end
  
  def save_data_create_object_associations(objects)
   
    @profile = MetaRailsProfile.new if @profile.nil?
   
    params[:parent_index].each do |child, parent| 
    
      child_name = objects[child.to_i].class.to_s
      parent_name = objects[parent.to_i].class.to_s
      assoc_types = @profile.associations_for(child_name,parent_name) 
      if assoc_types.nil?
        child,parent = parent,child
        child_name, parent_name = parent_name, child_name
        assoc_types = @profile.associations_for(child_name,parent_name) 
      end
      
      case assoc_types[0]        
        when "belongs_to","has_one"
          objects[child.to_i].send((parent_name.tableize.singularize+'=').to_sym, objects[parent.to_i]) 
        when "has_many", "has_and_belongs_to_many" #FIXME: test habtm
          objects[child.to_i].send(parent_name.tableize.pluralize).send("<<",objects[parent.to_i])
      end unless assoc_types.nil?
  
    end if params[:parent_index]
    
    objects.each do |obj| 
      if !obj.save 
        return obj.errors.full_messages[0]
      end
    end
   
    "Data saved successfully"
  end

  def update_form_data
    raise "Not developed"
  end
  
  # Manage forms
  def create_form
    
    new_form=true
    if params[:form]
      @form = MetaFormsForm.create(params[:form])
      new_form = false
    end
    
    redirect_to :action => :edit, :id => @form, :new_form => new_form
  end
  
  def update_form
    if params[:form] && params[:form_id]
      @form = MetaFormsForm.find params[:form_id]
      @form.update_attributes params[:form]
    end
    redirect_to :action => :edit, :id => params[:form_id]
  end
  
  def delete_form
    if params[:id]
      MetaFormsForm.delete(params[:id])
    end
    redirect_to :action => params[:next_action] || :list
  end
  
  # Manage form tables
  def add_form_table
    if params[:form_id]
      @form = MetaFormsForm.find params[:form_id]
      form_table = MetaFormsFormTable.create params[:form_table]
      form_table.add_forms_attributes(@activerecord_columns[form_table.table_name])
      #FIXME: BEGIN DATACATEGORY RELATED
      if defined? DataCategory
        dcs = {}; DataCategory.get_possible_datacats_for_class(form_table.table_name.classify).each {|dc| dcs[dc.id.to_s] = :data_category}
        form_table.add_forms_attributes(dcs)
      end
      #FIXME: END DATACATEGORY RELATED
      @form.meta_forms_form_table = form_table
      @form.update      
    end
    redirect_to :action => :edit, :id => params[:form_id]
  end
  
  def update_form_table
    if params[:form_table] && params[:id]
      @form_table = MetaFormsFormTable.find params[:id]
      @form_table.update_attributes params[:form_table]
    end    
    redirect_to :action => :edit, :id => params[:form_id]    
  end
  
  def delete_form_table
    if params[:id]
      MetaFormsFormTable.delete(params[:id])
    end
    #redirect_to :action => params[:next_action] || :edit
    redirect_to :action => :edit, :id => params[:form_id]    
  end
  
  def add_related_form_table
    if params[:id]
      parent_form_table = MetaFormsFormTable.find params[:id]
      child_form_table = MetaFormsFormTable.create params[:form_table]
      child_form_table.add_forms_attributes(@activerecord_columns[child_form_table.table_name])
      #FIXME: BEGIN DATACATEGORY RELATED
      if defined? DataCategory
        dcs = {}; DataCategory.get_possible_datacats_for_class(child_form_table.table_name.classify).each {|dc| dcs[dc.id.to_s] = :data_category}
        child_form_table.add_forms_attributes(dcs)
      end
      #FIXME: END DATACATEGORY RELATED
      parent_form_table.meta_forms_form_tables << child_form_table
      parent_form_table.update 
      
    end
    redirect_to :action => :edit, :id => params[:form_id]
  end
  
  # Manage table attributes
  def update_table_attributes
    if params[:table_attributes]
      params[:table_attributes].each_pair do |attr_id, attr|
        attribute = MetaFormsAttribute.find attr_id
        attribute.update_attributes attr
      end
    end
    redirect_to :action => :edit, :id => params[:form_id]
  end
  
  def delete_table_attribute
    if params[:id]
      MetaFormsAttribute.delete(params[:id])
    end
    redirect_to :action => :edit, :id => params[:form_id]        
  end
  
  def add_removed_attr_to_form_table
    if params[:id]
      form_table = MetaFormsFormTable.find params[:id]
      # Select the attribute and reconvert the .select return value (array) into
      # a hash.
      attr_to_add = Hash[*@activerecord_columns[form_table.table_name].select {|key, value| key == params["attr_name"] }.flatten]
      if attr_to_add.empty?
        dcs = DataCategory.get_possible_datacats_for_class(form_table.table_name)
        dc_name = dcs.select {|dc| dc.name == params["attr_name"]}.first.id.to_s
        attr_to_add = {dc_name => :data_category}
      end
      form_table.add_forms_attributes(attr_to_add)
    end
    redirect_to :action => :edit, :id => params[:form_id]
  end
  
  def save_table_default_value
    if params[:id]
      form_table = MetaFormsFormTable.find params[:id]
      form_table.default_id_value = params[:selected_id]
      form_table.save
      redirect_to :action => :edit, :id => params[:form_id]
    end    
  end
  
end
  