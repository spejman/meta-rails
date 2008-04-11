class MetaWebServicesWs::<%= ws_name.camelize.pluralize %>Api < ActionWebService::API::Base

  api_method :show,
    :expects => [{:id => :int}],
	:returns => [<%= klass %>]

  api_method :list,
	:returns => [[<%= klass %>]]
	
  api_method :new,
	:expects => [<%= attr_hash_with_type %>],
	:returns => [<%= klass %>]

  api_method :update,
	:expects => [{:id => :int}, <%= attr_hash_with_type %>],
	:returns => [<%= klass %>]
  
  api_method :delete,
    :expects => [{:id => :int}],
	:returns => [:bool]

  <% klass_attr.keys.each do |attr| %>
  api_method :find_by_<%= attr %>,
    :expects => [{:attr => :<%= klass_attr[attr] %>}],
    :returns => [[<%= klass %>]]
  <% end if klass_attr -%>

  <% habtm.each do |habtm_klass| %>
  api_method :<%= habtm_klass.underscore.pluralize %>,
    :expects => [{:<%= klass.underscore.singularize %>_id => :int}],
	:returns => [[<%= habtm_klass.underscore.classify %>]]

  api_method :add_<%= habtm_klass.underscore.singularize %>,
    :expects => [{:<%= klass.underscore.singularize %>_id => :int}, {:<%= habtm_klass.underscore.singularize %>_id => :int} ],
	:returns => [[<%= habtm_klass.underscore.classify %>]]

  api_method :remove_<%= habtm_klass.underscore.singularize %>,
    :expects => [{:<%= klass.underscore.singularize %>_id => :int}, {:<%= habtm_klass.underscore.singularize %>_id => :int}],
	:returns => [[<%= habtm_klass.underscore.classify %>]]    
  <% end -%>

  <%= extra_methods %>

end