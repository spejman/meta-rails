# Include hook code here
directory = "#{RAILS_ROOT}/vendor/plugins/meta_querier"

controller_path = File.join(directory, 'app', 'controllers')

$LOAD_PATH << controller_path
if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION >= '1.2.0'
  Dependencies.load_paths << controller_path
else
  raise "Engines plugin is needed for running meta_querier with a Ruby on Rails version < 1.2.0" if Dir["#{RAILS_ROOT}/vendor/plugins/engines"].empty?
end
config.controller_paths << controller_path

require "meta_querier"

unless MetaQuerierQuery.table_exists?
  ActiveRecord::Schema.create_table(MetaQuerierQuery.table_name) do |t|
    t.column :name, :string
    t.column :query, :text
    t.column :description, :text
    t.column :history, :boolean, :default => true
    t.column :user_id, :integer, :limit => 10, :default => 0, :null => true
    t.column :created_at,     :datetime
    t.column :updated_at,     :datetime
  end
end

unless MetaQuerierQueryCondition.table_exists?
  ActiveRecord::Schema.create_table(MetaQuerierQueryCondition.table_name) do |t|
    t.column :route, :text
    t.column :description, :text
    t.column :position, :integer # Position in node[:conditions] array
    t.column :meta_querier_query_id, :integer, :limit => 10, :default => 0, :null => false
    t.column :created_at,     :datetime
    t.column :updated_at,     :datetime
  end
end