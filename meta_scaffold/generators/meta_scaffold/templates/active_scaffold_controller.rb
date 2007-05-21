class MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller < ApplicationController
    layout "meta_scaffold"
	active_scaffold :<%= class_name.underscore.singularize %>
  
  before_filter :set_meta_scaffold_class_name

  def set_meta_scaffold_class_name
    @meta_scaffold_class_name = "<%= class_name.camelize.singularize %>"
  end

end
