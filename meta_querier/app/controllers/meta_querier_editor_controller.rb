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
    editing_model_id = nil
    @query = MetaQuerierQuery.find params[:id]
    if (join_hash = params[:join])      
      meta_query = @query.query
      @new_model = meta_query.add_model join_hash[:parent_id], join_hash[:model_name],
          join_hash[:position],
          @activerecord_columns[join_hash[:model_name].classify],
          @activerecord_associations[join_hash[:model_name].classify]
      @new_model.possible_columns.each do |c_name, c_type|        
        meta_query.add_field @new_model.id, c_name, c_name.camelcase.humanize, c_type
      end
      @query.save
      editing_model_id = @new_model.id
    end
    redirect_to_edit(@query, editing_model_id, :models)
  end
  
  def remove_join
    @query = MetaQuerierQuery.find params[:id]
    removed_models = @query.query.remove_model(params[:model_id])
    @query.save    
    removed_models_ids = removed_models.collect {|rm| rm.id }
    
    # if is parametrizable delete the database copy.
    @query.meta_querier_query_conditions.select do |mqqc|
        removed_models_ids.include? mqqc.model_id
    end.each {|mqqc_to_remove| mqqc_to_remove.destroy }
    
    redirect_to_edit(@query, params[:parent_model_id], :models)
  end
  
  def add_field
    @query = MetaQuerierQuery.find params[:id]
    unless params[:field][:as_name].blank?
      @query.query.add_field params[:model_id], params[:field][:column_name], params[:field][:as_name], params[:field][:field_type].to_sym
      @query.save
      redirect_to_edit(@query, params[:model_id], :fields)
    else
      @error_text = "Name of the field cannot be blank."
      render :action => "../meta_querier/error"
    end
  end
    
  def remove_field
    @query = MetaQuerierQuery.find params[:id]
    @removed_field = @query.query.remove_field params[:model_id], params[:field_index].to_i    
    @query.save
    redirect_to_edit(@query, params[:model_id], :fields)
  end

  def set_order_by
    @query = MetaQuerierQuery.find params[:id]
    @query.query.add_order_by(params[:order_by], params[:direction])
    @query.save
    redirect_to_edit(@query, "order_by")    
  end

  def remove_order_by
    @query = MetaQuerierQuery.find params[:id]
    @query.query.remove_order_by(params[:order_by_index].to_i)
    @query.save
    redirect_to_edit(@query, "order_by")
  end
  
  def change_order_field
    @query = MetaQuerierQuery.find params[:id]
    a, b = @query.query.fields[params[:old_pos].to_i], @query.query.fields[params[:new_pos].to_i]
    @query.query.fields[params[:old_pos].to_i], @query.query.fields[params[:new_pos].to_i] = b, a
    @query.save
    redirect_to_edit(@query, "order_by")
  end
  
  def add_condition
    @query = MetaQuerierQuery.find params[:id]
    #TODO Check value to accomplish column datatype restrictions.
#    parent_model = @query.query.get_model params[:model_id]
#    data_type = parent_model.possible_columns[params[:condition][:column_name]]

    condition = @query.query.add_condition params[:model_id], params[:condition][:column_name],
                               params[:condition][:operation], params[:condition][:value],
                               params[:condition][:condition_type], params[:condition][:parametrizable]

    if condition.parametrizable?
      condition.parameter_description = params[:condition][:parameter][:description]
      MetaQuerierQueryCondition.create :meta_querier_query_id => @query.id,
        :model_id => params[:model_id], :condition_index => @query.query.get_model(params[:model_id]).condition_index(condition),
        :data_type => condition.value_type.to_s, :description => condition.parameter_description        
    end
    @query.save
    redirect_to_edit(@query, params[:model_id], :conditions)
  end
  
  def remove_condition
    @query = MetaQuerierQuery.find params[:id]
    @removed_condition = @query.query.remove_condition params[:model_id], params[:condition_index].to_i
    
    # if is parametrizable delete the database copy.
    @query.meta_querier_query_conditions.select do |mqqc| 
      (mqqc.condition_index == params[:condition_index].to_i) &&
        (mqqc.model_id == params[:model_id])
    end[0].destroy if @removed_condition.parametrizable?
    
    # if some condition is parametrizable actualize conditions indexes of 
    # the database copies.
    if @query.query.get_model(params[:model_id]).parametrizable?
      @query.meta_querier_query_conditions.select do |mqqc| 
        (mqqc.condition_index > params[:condition_index].to_i) &&
          (mqqc.model_id == params[:model_id])
      end.each do |mqqc|
        mqqc.condition_index -= 1
        mqqc.save
      end
    end
    
    @query.save
    redirect_to_edit(@query, params[:model_id], :conditions)
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
  
  private
    def redirect_to_edit(query, editing_model_id = nil, context = nil)
      redirect_to :controller => "meta_querier", :action => "edit", :id => query, :editing_model_id => editing_model_id, :context => context
    end
  
end
