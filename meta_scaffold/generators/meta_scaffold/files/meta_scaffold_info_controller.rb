require "infer_db_model"
include MetaRails::InferDbModel
require "meta_scaffold_controllers"
include MetaRails::MetaScaffoldControllers
require "xml_data_to_db"
include MetaRails::XmlDataToDb

class MetaScaffoldInfoController < ApplicationController

  def index
    actualize_profile_selected
    flash[:notice] = params[:message] if params[:message]
  end

  def insert_xml_data
    actualize_profile_selected
    insert_xml_data_into_db(Document.new(params[:xml_file].read).root, @klasses_struct)
    redirect_to :action => index, :message => "XML data inserted"
  end
end
