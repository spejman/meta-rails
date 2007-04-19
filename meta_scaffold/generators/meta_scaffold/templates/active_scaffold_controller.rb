class MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller < ApplicationController
    layout "meta_scaffold"
	active_scaffold :<%= class_name.underscore.singularize %>
end
