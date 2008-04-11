require "meta_rails_common"
include MetaRails
require "infer_db_model"
include MetaRails::InferDbModel
require "xml_data_to_db"
include MetaRails::XmlDataToDb


class MetaBulkDataController < ApplicationController
  
  
  before_filter :load_avariable_profiles
  before_filter :load_db_data
  
  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_bulk_data/app/views/"
  layout select_layout("meta_bulk_data")
  
  def index
    flash[:notice] = params[:message] if params[:message]
  end

  def insert_xml_data    
    insert_xml_data_into_db(Document.new(params[:xml_file].read).root, @klasses_struct)
    redirect_to :action => index, :message => "XML data inserted"
  end
  
  protected  
  def load_avariable_profiles
    session[:profile] ||= "ALL"
    session[:profile] = params[:profile] if params[:profile]

    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}    
  end

  # Inialization method
  #   - Checks if meta querier tables exists
  #   - Loads avariable profiles at @avariable_profiles
  #   - Creates @klasses_struct will all the profile related db data.
  #   - Fills @activerecord_classes, @activerecord_columns, @activerecord_associations global variables.
  def load_db_data
    if @avaliable_profiles.include? session[:profile]
      flash[:notice] = "Profile changed" if params[:profile]
      @klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
    else
      session[:profile] = "ALL"
      flash[:notice] = "Profile #{params[:profile]} doesn't exist using default profile #{session[:profile]}" if params[:profile]
      @klasses_struct = klass_struct
    end

    @activerecord_classes = @klasses_struct.keys
    @activerecord_columns = {}
    @klasses_struct.each {|klass_name, values| @activerecord_columns[klass_name] = (values["class_attr"] || {})}
    @activerecord_associations = {}
    @klasses_struct.each do |klass_name, values|
      @activerecord_associations[klass_name] = {}
      values["class_ass"].map{|e| e.to_a.flatten}.each {|rel| @activerecord_associations[klass_name][rel[1]] = rel[0]}
    end
    @actual_query = session[:actual_query]
    meta_querier_activerecord_associations_hook if defined?(meta_querier_activerecord_associations_hook) == "method"
  end

  
end
