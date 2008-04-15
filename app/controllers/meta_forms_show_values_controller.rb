
class MetaFormsShowValuesController < ApplicationController

  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_rails/app/views/"
  
  def index
    @klass_name = params[:id].classify
    @klass = @klass_name.constantize
    @values = @klass.paginate :page => params[:page], :per_page => 10
    @klass_data_categories = DataCategory.get_possible_datacats_for_class(@klass_name)
    
    render :action => "table", :layout => false
  end
  
  
end