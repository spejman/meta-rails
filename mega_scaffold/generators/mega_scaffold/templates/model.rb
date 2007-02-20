class <%= class_name.singularize.camelize %> < ActiveRecord::Base
	<% class_ass.each do |relation| %>
	 <%= relation.keys[0] %> :<%= relation.values[0].tableize %>
	<% end -%>
end
