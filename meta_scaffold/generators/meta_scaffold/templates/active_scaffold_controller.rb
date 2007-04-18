class <%= class_name.camelize.pluralize %>Controller < ApplicationController
	active_scaffold :<%= class_name.underscore.singularize %>
end
