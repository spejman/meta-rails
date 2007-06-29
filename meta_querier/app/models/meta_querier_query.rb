class MetaQuerierQuery < ActiveRecord::Base
  set_table_name 'meta_querier_queries'
  has_many :meta_querier_query_conditions

  serialize :query
end
