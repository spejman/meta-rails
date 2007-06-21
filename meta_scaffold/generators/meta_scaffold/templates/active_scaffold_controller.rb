require "infer_db_model"
include MetaRails::InferDbModel

class MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller < ApplicationController
  layout "meta_scaffold"
	active_scaffold :<%= class_name.underscore.singularize %>
  
  before_filter :set_meta_scaffold_class_name
  before_filter :set_profile
  after_filter  :clear_profile


  private

  def set_profile
    MetarailsSingleton.current_profile = session[:profile]
  end
  
  def clear_profile
    MetarailsSingleton.current_profile = nil
  end

  def set_meta_scaffold_class_name
    meta_scaffold_class_name = "<%= class_name.camelize.singularize %>"

    session[:profile] ||= "all"
    session[:profile] = params[:profile] if params[:profile]
    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}

    if @avaliable_profiles.include? session[:profile]
      klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
    else
      klasses_struct = klass_struct
    end

    desired_columns = klasses_struct[meta_scaffold_class_name]["class_ass"].collect { |pair| pair.values[0].to_sym }
    desired_columns += klasses_struct[meta_scaffold_class_name]["class_attr"].keys.collect(&:to_sym) if klasses_struct[meta_scaffold_class_name]["class_attr"]
    MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller.active_scaffold_config.configure do |conf|
      #conf.list.label = desired_columns.collect(&:to_s).join(",")
      actual_cols = []; conf.list.columns.each{|c| actual_cols << c.name}
      used_columns = actual_cols - desired_columns
      conf.list.columns.exclude(used_columns)
      conf.show.columns.exclude(used_columns)
      conf.update.columns.exclude(used_columns)
      conf.create.columns.exclude(used_columns)  
    end
    @klasses_struct = klasses_struct
    @meta_scaffold_class_name = meta_scaffold_class_name
    
  end

end
