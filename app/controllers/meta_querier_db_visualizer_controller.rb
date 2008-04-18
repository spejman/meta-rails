# Ruby on Rails Controller that loads itself at /meta_querier_db_visualizer url
# of the application.
# 
# Generates diagrams for visualizing the database data.
#
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org
require "meta_querier"

class MetaQuerierDbVisualizerController < MetaQuerierControllersCommon
  DEFAULT_EXTENSION = "png"
  
  before_filter :load_db_data
   
  # Generates the image and redirects to the correct image path.
  def index
    if model = params[:model]
      @model_names = [params[:model]]
      @model_names << @klasses_struct[@model_names[0]]["class_ass"].collect {|rel| rel.values[0].to_s.classify }
      @model_names.flatten!
    else
      @model_names = @klasses_struct.keys
    end
    extension = session[:extension] || "#{DEFAULT_EXTENSION}"
    respond_to do |format|
      format.png { extension = "png"}
      format.pdf { extension = "pdf"}
    end
    session[:extension] = extension
    
    image_filename = "/images/meta_rails/meta_querier/" + Digest::MD5.hexdigest(@model_names.join("#")).to_s + "." + extension
    image_path = "#{RAILS_ROOT}/public#{image_filename}"
    # Create the image only if not exists
    unless File.exists? image_path
      rav = MetaRails::MetaQuerier::RailsApplicationVisualizer.new({ :model_names => @model_names, :model_columns => @activerecord_columns,
                                                          :model_associations => @activerecord_associations,
                                                          :actual_model => params[:model] })    
      rav.output image_path
    end
    redirect_to image_filename    
  end
  
end
