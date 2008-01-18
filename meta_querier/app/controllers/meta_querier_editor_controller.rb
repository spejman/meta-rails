# Ruby on Rails Controller that loads itself at /meta_querier url
# of the application.
# 
# Provides tools for editing the query.
#
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org
require "meta_querier_controllers_common"

class MetaQuerierEditorController < MetaQuerierControllersCommon
  before_filter :load_db_data, :only => [:add_join]
  
  def add_join
    @query = MetaQuerierQuery.find params[:id]
    if (join_hash = params[:join])      
      meta_query = @query.query
      @new_model = meta_query.add_model join_hash[:parent_id], join_hash[:model_name],
          join_hash[:position],
          @activerecord_columns[join_hash[:model_name].classify],
          @activerecord_associations[join_hash[:model_name].classify]
      @new_model.possible_columns.each do |c_name, c_type|
        meta_query.add_field @new_model.id, c_name, "#{@new_model.id}_#{c_name.camelcase}", c_type
      end
      @query.save
    end
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query
  end
  
  def remove_join
    @query = MetaQuerierQuery.find params[:id]
    @query.query.remove_model(params[:model_id])
    @query.save
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query
  end
  
  def add_field
    @query = MetaQuerierQuery.find params[:id]
    @query.query.add_field params[:model_id], params[:field][:column_name], params[:field][:as_name], params[:field][:field_type].to_sym
    @query.save
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query      
  end
  
  def remove_field
    @query = MetaQuerierQuery.find params[:id]
    @removed_field = @query.query.remove_field params[:model_id], params[:field_index].to_i    
    @query.save
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query      
  end
  
  def add_condition
    @query = MetaQuerierQuery.find params[:id]
    #TODO Check value to accomplish column datatype restrictions.
#    parent_model = @query.query.get_model params[:model_id]
#    condition_type = parent_model.possible_columns[params[:condition][:column_name]]
    condition = @query.query.add_condition params[:model_id], params[:condition][:column_name],
                               params[:condition][:operation], params[:condition][:value],
                               params[:condition][:condition_type], params[:condition][:parametrizable]
    if condition.parametrizable?
      condition.parameter_description = params[:condition][:parameter][:description]
      MetaQuerierQueryCondition.create :meta_querier_query_id => @query.id,
        :model_id => params[:model_id], :condition_index => @query.query.get_model(params[:model_id]).condition_index(condition),
        :description => condition.parameter_description        
    end
    @query.save
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query          
  end
  
  def remove_condition
    @query = MetaQuerierQuery.find params[:id]
    @removed_condition = @query.query.remove_condition params[:model_id], params[:condition_index].to_i
    
    # if is parametrizable delete the database copy.
    @query.meta_querier_query_conditions.select do |mqqc| 
      mqqc.condition_index == params[:condition_index].to_i
    end[0].destroy if @removed_condition.parametrizable?
    
    # if some condition is parametrizable actualize conditions indexes of 
    # the database copies.
    if @query.query.get_model(params[:model_id]).parametrizable?
      mqqc_to_update = @query.meta_querier_query_conditions.select { |mqqc| mqqc.condition_index > params[:condition_index].to_i}
      mqqc_to_update.each do |mqqc|
        mqqc.condition_index -= 1
        mqqc.save
      end
    end
    
    @query.save
    redirect_to :controller => "meta_querier", :action => "edit", :id => @query    
  end
  
  def condition_change_in_form
    if !params[:column_name].nil? && !params[:column_name].blank?
    @query = MetaQuerierQuery.find params[:id]
    model = @query.query.get_model params[:model_id]
    case model.field_type(params[:column_name])
      when :data_category
        @data_category = DataCategory.find model.data_categories_ids[params[:column_name]]
        render :partial => "condition_in_form_data_category"
      else
          render :partial => "condition_in_form_default"
    end
    else
      render :text => "Select a column name for the condition"
    end
  end
  
end
