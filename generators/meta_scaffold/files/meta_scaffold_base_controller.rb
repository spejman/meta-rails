require "meta_scaffold"

class MetaScaffoldBaseController < ApplicationController
  include MetaRails::MetaScaffold::ControllerMethods
  
  layout "meta_scaffold"
  
  before_filter :set_meta_scaffold_class_name 
  before_filter :set_profile
  after_filter  :clear_profile
end