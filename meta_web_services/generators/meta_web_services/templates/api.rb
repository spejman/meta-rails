class <%= ws_name.camelize.pluralize %>Api < ActionWebService::API::Base

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

  <% habtm.each do |habtm_klass| %>

  api_method :<%= habtm_klass.underscore.pluralize %>,
    :expects => [{:id => :int}],
	:returns => [[<%= habtm_klass.classify %>]]

  api_method :add_<%= habtm_klass.underscore.singularize %>,
    :expects => [{:id => :int}, {:<%= habtm_klass.underscore.singularize %>_id => :int} ],
	:returns => [[<%= habtm_klass.classify %>]]

  api_method :remove_<%= habtm_klass.underscore.singularize %>,
    :expects => [{:id => :int}, {:<%= habtm_klass.underscore.singularize %>_id => :int}],
	:returns => [[<%= habtm_klass.classify %>]]
    
  <% end %>


end