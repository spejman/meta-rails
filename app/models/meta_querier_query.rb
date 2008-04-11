# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Stores Queries
#
# Attributes:
#   * name => string
#   * description => string
#   * query => hash [serialized]
#   * history => boolean
#   * user_id => integer
#   * created_at, updated_at => datetime

class MetaQuerierQuery < ActiveRecord::Base
  set_table_name 'meta_querier_queries'
  has_many :meta_querier_query_conditions

  serialize :query
end
