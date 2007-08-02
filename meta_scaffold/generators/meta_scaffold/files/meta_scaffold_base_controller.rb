require "infer_db_model"
include MetaRails::InferDbModel
require "meta_scaffold_controllers"

class MetaScaffoldBaseController < ApplicationController
  include MetaRails::MetaScaffoldControllers
  
  layout "meta_scaffold"
  
  before_filter :set_meta_scaffold_class_name 
  before_filter :set_profile
  after_filter  :clear_profile
end