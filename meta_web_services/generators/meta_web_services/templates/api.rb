class <%= ws_name.camelize.pluralize %>Api < ActionWebService::API::Base
  api_method :show,
    :expects => [{:id => :int}],
	:returns => [<%= klass %>]
  api_method :list,
	:returns => [[<%= klass %>]]
  api_method :new,
	:expects => [{:name => :string}, {:otracosa => :string}, {:otro_id => :int}, {:lexical_entries => [:int]}],
	:returns => [<%= klass %>]

  api_method :update
  api_method :delete

end