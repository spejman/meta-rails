require "meta_scaffold/controller_methods"
require "meta_bulk_data"


class MetaScaffoldInfoController < ApplicationController
  include MetaRails::MetaScaffold::ControllerMethods
  include MetaRails::MetaBulkDataXmlDataToDb  
  
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
