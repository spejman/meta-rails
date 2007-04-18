class Create<%= class_name.camelize %> < ActiveRecord::Migration
  def self.up

    create_table :<%= class_name.tableize.pluralize %> do |t|
    <% class_attr.each do |name, type| -%>
      t.column "<%= name %>", :<%= type %>
    <% end -%>
    <% fks.each do |name| -%>
      t.column "<%= name %>", :integer, :limit => 10, :default => 0, :null => false
    <% end -%>
    end
    <% unless habtm.empty? %>
    <% habtm.each do |habtm_name| -%>
    create_table :<%= class_name.tableize %>_<%= habtm_name.tableize %>, :id => false, :force => true do |t|
      t.column "<%= class_name.singularize %>_id", :integer, :limit => 10, :default => 0, :null => false
      t.column "<%= habtm_name.singularize %>_id", :integer, :limit => 10, :default => 0, :null => false
    end     
    <% end -%>
    <% end -%>
  end

  def self.down
    drop_table :<%= class_name.tableize.pluralize %>
  end
end
