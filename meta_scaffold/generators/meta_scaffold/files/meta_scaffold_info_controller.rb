require "infer_db_model"
include MetaRails::InferDbModel
require "meta_scaffold_controllers"
include MetaRails::MetaScaffoldControllers

class MetaScaffoldInfoController < ApplicationController

  def index
    actualize_profile_selected    
  end

end
