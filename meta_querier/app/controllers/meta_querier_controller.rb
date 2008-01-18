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

class MetaQuerierController < MetaQuerierControllersCommon

  before_filter :load_db_data, :only => [:edit]
# ACTIONS
  def index
    
  end

  def list
    @queries = MetaQuerierQuery.find :all, :order => "updated_at desc"
  end
  
  def new
    if params[:query]
      @query = MetaQuerierQuery.create params[:query]
      @query.query = MetaQuery::Query.new
      @query.save
      redirect_to :action => "edit", :id => @query.id
    end
  end
    
  def edit
     MetaQuery::Query.new # This is needed in order to unserialize @query.query, I don't know why...
    @query = MetaQuerierQuery.find params[:id]
    @meta_query = @query.query
  end
  
  def delete
    #FIXME Make this more secure
    MetaQuerierQuery.find(params[:id]).destroy
    redirect_to :action => "list"
  end
  
  def copy
    @query = MetaQuerierQuery.find params[:id]
    query_copy = @query.clone
    query_copy.name += " [COPY]"
    @query.meta_querier_query_conditions.each do |mqqc|
      query_copy.meta_querier_query_conditions << mqqc.clone
    end
    query_copy.save
    redirect_to :action => "list"
  end
  
end
