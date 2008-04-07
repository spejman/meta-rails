
class MetaScaffoldModels::<%= class_name.camelize.pluralize %>Controller < MetaScaffoldBaseController
	active_scaffold :<%= class_name.underscore.singularize %>
end
