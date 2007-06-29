class MetaQuerierQueryCondition < ActiveRecord::Base
  set_table_name 'meta_querier_query_conditions'
  belongs_to :meta_querier_query
  
  serialize :route
end
