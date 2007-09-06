# MetaQuerier
require "sqldsl-1.4.2/sqldsl.rb"
require "meta_querier_rav"
require "infer_db_model"

# Load models
require File.dirname(__FILE__) + "/../app/models/meta_querier_query.rb"
require File.dirname(__FILE__) + "/../app/models/meta_querier_query_condition.rb"

# Check if MetaQuerier model tables exist in the DB
META_QUERIER_TABLES = MetaQuerierQuery.table_exists? && MetaQuerierQueryCondition.table_exists?

