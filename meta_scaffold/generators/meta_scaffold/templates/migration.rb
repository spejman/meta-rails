class Create<%= class_name.camelize %> < ActiveRecord::Migration
  def self.up

    <% if !class_attr.empty? || !fks.empty? -%>
      create_table :<%= class_name.tableize.pluralize %> do |t|
      <% class_attr.each do |name, type| -%>
         t.column "<%= name %>", :<%= type %>
      <% end -%>
      <% fks.each do |name| -%>
        t.column "<%= name %>_id", :integer, :limit => 10, :default => 0, :null => true
      <% end -%>
      end
    <% end -%>
    
    <% unless habtm.empty? -%>
      <% habtm.each do |habtm_name| -%>
        create_table :<%= (class_name.tableize < habtm_name.tableize) ? class_name.tableize : habtm_name.tableize %>_<%= (class_name.tableize > habtm_name.tableize) ? class_name.tableize : habtm_name.tableize %>, :id => false, :force => true do |t|
          t.column "<%= class_name.singularize %>_id", :integer, :limit => 10, :default => 0, :null => false
          t.column "<%= habtm_name.singularize %>_id", :integer, :limit => 10, :default => 0, :null => false
        end     
      <% end -%>
    <% end -%>
    
    <% add.each do |name, type| -%>
      add_column :<%= class_name.tableize.pluralize %>, :<%= name %>, :<%= type %>
    <% end -%>    

    <% remove.each do |name| -%>
      remove_column :<%= class_name.tableize.pluralize %>, :<%= name %>
    <% end -%>    

    <% modify.each do |name, type| -%>
      remove_column :<%= class_name.tableize.pluralize %>, :<%= name %>    
      add_column :<%= class_name.tableize.pluralize %>, :<%= name %>, :<%= type %>
    <% end -%>    
    
  end

  def self.down
    drop_table :<%= class_name.tableize.pluralize %>
    <% habtm.each do |habtm_name| -%>
    drop_table :<%= (class_name.tableize < habtm_name.tableize) ? class_name.tableize : habtm_name.tableize %>_<%= (class_name.tableize > habtm_name.tableize) ? class_name.tableize : habtm_name.tableize %>
    <% end -%>

  end
end
