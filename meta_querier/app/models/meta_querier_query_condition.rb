# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Stores Query conditions
#
# Attributes:
#   * route => hash [serialized]
#   * description => string
#   * position => integer
#   * is_selected => boolean
#   * created_at, updated_at => datetime

class MetaQuerierQueryCondition < ActiveRecord::Base
  set_table_name 'meta_querier_query_conditions'
  belongs_to :meta_querier_query
  
  serialize :route
end
