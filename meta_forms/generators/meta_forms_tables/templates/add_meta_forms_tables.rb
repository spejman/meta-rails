# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Migration that creates MetaQuerier tables needed for saving
# Queries and its conditions.
class AddMetaFormsTables < ActiveRecord::Migration
  def self.up
    create_table(MetaFormsForm.table_name) do |t|
      t.column :name, :string
      t.column :description, :text
      t.column "#{MetaFormsFormTable.table_name.underscore.singularize}_id", :integer, :limit => 10, :default => 0, :null => true
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end
  
    create_table(MetaFormsFormTable.table_name) do |t|
      t.column :table_name, :string
      t.column :name, :string
      t.column :description, :text
      t.column :hidden, :boolean, :default => false
      t.column :default_id_value, :integer      
      t.column "#{MetaFormsFormTable.table_name.underscore.singularize}_id", :integer, :limit => 10, :default => 0, :null => true
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end

    create_table(MetaFormsAttribute.table_name) do |t|
      t.column :attr_name, :string
      t.column :name, :string
      t.column :description, :text
      t.column :hidden, :boolean, :default => false
      t.column :compulsory, :boolean, :default => false      
      t.column :default_value, :string      
      t.column :field_type, :string
      t.column "#{MetaFormsFormTable.table_name.underscore.singularize}_id", :integer, :limit => 10, :default => 0, :null => true
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end

  end

  def self.down
    drop_table MetaFormsAttribute.table_name
    drop_table MetaFormsFormTable.table_name    
    drop_table MetaFormsForm.table_name    
  end
end