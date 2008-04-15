# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# MetaQuerier
require "sqldsl-1.4.2/sqldsl.rb"
require "meta_querier_rav"


# Load models
require File.dirname(__FILE__) + "/../app/models/meta_querier_query.rb"
require File.dirname(__FILE__) + "/../app/models/meta_querier_query_condition.rb"

# Check if MetaQuerier model tables exist in the DB
META_QUERIER_TABLES = MetaQuerierQuery.table_exists? && MetaQuerierQueryCondition.table_exists?

MODIFY_QUERY_C = "meta_querier_modify_query"

META_QUERIER_HOOK_FILE = "#{RAILS_ROOT}/lib/meta_querier_hook.rb"
