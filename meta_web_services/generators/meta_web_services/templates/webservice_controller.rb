class <%= ws_name.camelize.pluralize %>Controller < ApplicationController
  wsdl_service_name '<%= ws_name.camelize.pluralize %>'
  web_service_scaffold :invoke

  def show(id)
    <%= klass %>.find id
  end

  # Return an array of all the <%= klass %> objects that exist. 
  def list
	<%= klass %>.find :all
  end

  def new(<%= attr_list %>)
   <% fks.each do |fk| -%>
	   <%= fk %>_id = nil if <%= fk %>_id < 0
	   raise "<%= fk %> invalid" unless <%= fk %>_id.nil? or <%= fk.classify %>.find(<%= fk %>_id)
	 <% end -%>
	   k = <%= klass %>.new(<%= attr_hash %>)
	   k.save
	   return k
  end

  def update(id, <%= attr_list %>)
    k = <%= klass %>.find id
    raise "<%= klass %> with id #{id} not found" unless k
    k.attributes = {<%= attr_hash %>}
    k.update
    k
  end

  def delete(id)
    return <%= klass %>.delete(id)    
  end
  
  # FindBy#{Attibute} methods that return an array of the objects that
  # have the attribute equal to given value.
  <% klass_attr.keys.each do |attr| %>
  def find_by_<%= attr %>(<%= attr %>)
    <%= klass %>.find_all_by_<%= attr %>(<%= attr %>)
  end
  <% end if klass_attr -%>

  # Has and belongs to many management methods (view, add and remove)
  <% habtm.each do |habtm_klass| %>  
  def <%= habtm_klass.underscore.pluralize %>(id)
    k = <%= klass %>.find id
    k.<%= habtm_klass.underscore.pluralize %>
  end

  def add_<%= habtm_klass.underscore.singularize %>(id, habtm_id)
    k = <%= klass %>.find id
    habtm = <%= habtm_klass.classify %>.find habtm_id
    k.<%= habtm_klass.underscore.pluralize %> << habtm
    k.update
    k.<%= habtm_klass.underscore.pluralize %>
  end

  def remove_<%= habtm_klass.underscore.singularize %>(id, habtm_id)
    k = <%= klass %>.find id
    habtm = <%= habtm_klass.classify %>.find habtm_id
    k.<%= habtm_klass.underscore.pluralize %> -= [habtm]
    k.update
    k.<%= habtm_klass.underscore.pluralize %>
  end  
  <% end -%>
  
end