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
    list
    render :action => "list"
  end

  def list
    MetaQuery::Query.new # This is needed in order to unserialize @query.query, I don't know why...
    @queries = MetaQuerierQuery.find :all, :order => "updated_at desc"
  end
  
  def new
    if params[:query]
      @query = MetaQuerierQuery.create params[:query]
      @query.query = MetaQuery::Query.new 
      @query.save
      redirect_to :action => "edit", :id => @query.id, :profile => @query.profile
    end
  end
  
  def update_query_info
    if params[:query]
      @query = MetaQuerierQuery.find params[:id]
      @query.description = params[:query][:description]
      @query.name = params[:query][:name]
      @query.save
    end
    redirect_to :action => "edit", :id => @query.id, :profile => @query.profile
  end
    
  def edit
     MetaQuery::Query.new # This is needed in order to unserialize @query.query, I don't know why...
    @query = MetaQuerierQuery.find params[:id]
    @meta_query = @query.query
    @editing_model_id = params[:editing_model_id] || @meta_query.root[0].id unless @meta_query.root.empty?
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
