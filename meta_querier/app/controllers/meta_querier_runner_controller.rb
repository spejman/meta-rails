# Ruby on Rails Controller that loads itself at /meta_querier url
# of the application.
# 
# Provides tools for doing advanced queries to the tables of the application.
#
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org
require "meta_querier_controllers_common"

# Ruby on Rails Controller that loads itself at /meta_querier url
# of the application.
# 
# Provides tools for doing advanced queries to the tables of the application.

class MetaQuerierRunnerController < MetaQuerierControllersCommon
  def run
    MetaQuery::Query.new # This is needed in order to unserialize @query.query, I don't know why...
    @query = MetaQuerierQuery.find params[:id]
    meta_query = @query.query
    @query.meta_querier_query_conditions.each do |mqqc|
      if !params[:conditions] || 
         !params[:conditions][mqqc.model_id] ||
         !params[:conditions][mqqc.model_id][mqqc.condition_index.to_s]
        render :action => "choose_condition_parameters"
        return
      end
      meta_query.set_parametrized_condition_value mqqc.model_id, mqqc.condition_index,
                      params[:conditions][mqqc.model_id][mqqc.condition_index.to_s]
    end
        
    @ar_base = ActiveRecord::Base.connection.select_all meta_query.to_sql
  end

end