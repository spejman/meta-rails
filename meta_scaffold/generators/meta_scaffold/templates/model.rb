class <%= class_name.singularize.camelize %> < ActiveRecord::Base
	<% class_ass.each do |relation| -%>
	   <%= relation.keys[0] %> :<%= (relation.keys[0] == "belongs_to" || relation.keys[0] == "has_one" )? relation.values[0].tableize.singularize : relation.values[0].tableize %>
	<% end %>
end
