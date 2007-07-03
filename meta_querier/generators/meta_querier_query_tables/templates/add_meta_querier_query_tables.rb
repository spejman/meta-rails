class AddMetaQuerierQueryTables < ActiveRecord::Migration
  def self.up
    create_table(MetaQuerierQuery.table_name) do |t|
      t.column :name, :string
      t.column :query, :text
      t.column :description, :text
      t.column :history, :boolean, :default => true
      t.column :user_id, :integer, :limit => 10, :default => 0, :null => true
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end
  
    create_table(MetaQuerierQueryCondition.table_name) do |t|
      t.column :route, :text
      t.column :description, :text
      t.column :position, :integer # Position in node[:conditions] array
      t.column :meta_querier_query_id, :integer, :limit => 10, :default => 0, :null => false
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end
  end

  def self.down
    drop_table MetaQuerierQueryCondition.table_name
    drop_table MetaQuerierQuery.table_name    
  end
end