require "infer_db_model"
include MetaRails::InferDbModel
require "meta_scaffold_controllers"


class MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller < ApplicationController
  include MetaRails::MetaScaffoldControllers
  
  layout "meta_scaffold"
	active_scaffold :<%= class_name.underscore.singularize %>
  
  before_filter :set_meta_scaffold_class_name 
  before_filter :set_profile
  after_filter  :clear_profile

end
