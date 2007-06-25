require "digest/md5"
require "fileutils"
require "meta_querier"
require "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/helpers/meta_querier_helper.rb"

include MetaQuerierHelper
include MetaRails::InferDbModel

class MetaQuerierController < ApplicationController
  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/views/"
  
  layout "application", :except => ["run_query_txt", "run_query_excel"]
 
  # ActAsAuthenticated hook
  if File.exists? "#{RAILS_ROOT}/vendor/plugins/acts_as_authenticated"
    include AuthenticatedSystem
    before_filter :do_login_if_required
    def do_login_if_required
      login_required if (!defined?(MetaQuerierUseActAsAuth) or MetaQuerierUseActAsAuth) and !logged_in?
    end
  end
# INIT methods
# 
  def init
    session[:profile] ||= "all"
    session[:profile] = params[:profile] if params[:profile]

    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}

    if @avaliable_profiles.include? session[:profile]
      @klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
    else
      @klasses_struct = klass_struct
    end

    # TODO: evaluate if will improve efficiency if we change necessary code in order to only 
    # use @klasses_struct instead of @tables, @activerecord_classes, @activerecord_columns 
    # and @activerecord_associations
    @tables = @klasses_struct.keys.map(&:tableize)
    @activerecord_classes = @klasses_struct.keys
    @activerecord_columns = {}
    @klasses_struct.each {|klass_name, values| @activerecord_columns[klass_name] = (values["class_attr"] || {})}
    @activerecord_associations = {}
    @klasses_struct.each do |klass_name, values|
      @activerecord_associations[klass_name] = {}
      values["class_ass"].map{|e| e.to_a.flatten}.each {|rel| @activerecord_associations[klass_name][rel[1]] = rel[0]}
    end
  end
# ACTIONS
# 

  def index
    init
    @actual_query = session[:actual_query]
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns) if session[:actual_query]
  end
  
  def get_image
    init
    @actual_query = session[:actual_query]
    if model = params[:model]
      @model_names = [params[:model]]
      @model_names << @klasses_struct[@model_names[0]]["class_ass"].collect {|rel| rel.values[0].to_s.classify }
      @model_names.flatten!
    else
      @model_names = @klasses_struct.keys
    end
    image_filename = "/images/meta_rails/meta_querier/" + Digest::MD5.new(@model_names.join("#")).to_s + ".png"
    image_path = "#{RAILS_ROOT}/public#{image_filename}"
    # Create the image only if not exists
    unless File.exists? image_path
      @q_sql = get_sql_for_query(@actual_query, @activerecord_columns) if session[:actual_query]    
      rav = MetaQuerier::RailsApplicationVisualizer.new({ :model_names => @model_names, :model_columns => @activerecord_columns,
                                                          :model_associations => @activerecord_associations,
                                                          :actual_model => params[:model],
                                                          :models => true, :controllers => false })    
      rav.output image_path
    end
    redirect_to image_filename
  end
  
  def clear_models_images_cache
    num_images = Dir["#{RAILS_ROOT}/public/images/meta_rails/meta_querier/*.png"].size
    Dir["#{RAILS_ROOT}/public/images/meta_rails/meta_querier/*.png"].each do |image_file|
      FileUtils.rm_f image_file
    end
    render :text => "Deleted #{num_images} images in models images cache"
  end
  
  def clear_query
    session[:actual_query] = nil
    init
    render :partial => "make_query"
  end
  
  def make_query
    init
    session[:actual_query] ||= []
    @actual_query = session[:actual_query]
    if params[:query] 
      @actual_query << add_new_model_for_query(params[:query][:model], 0, 0) if params[:query][:model]
    end
    # Get join conditions
    if params[:join]
      params[:join].each do |key, value|
        next if value.blank?
        route = get_route(key)
        join_position = search_model_in_query(@actual_query, route)
        new_join_deep = join_position[:deep]+1; new_join_wide = join_position[:join].size
        join_position[:join] << add_new_model_for_query(value, new_join_deep, new_join_wide, params[:join_type][key])
      end
    end
  
    # Get conditions for each model
    if params[:conditions_column] and (params[:conditions_op_string] or params[:conditions_op_integer]) \
        and params[:conditions_value] and params[:conditions_c_type]

      params[:conditions_column].each do |key, column_name|
        column_type = params[:conditions_c_type][key]

        if column_type == "string"
          conditions_op = params[:conditions_op_string][key]
        else
          conditions_op = params[:conditions_op_integer][key]
        end
        
        # jump to next if op and value fields are empty
        if column_type == "date"
          next unless params[:conditions_value_date]
          year = params[:conditions_value_date][key +"(1i)"]
          month = params[:conditions_value_date][key +"(2i)"]
          day = params[:conditions_value_date][key +"(3i)"]                    
          conditions_value = "\"#{month}-#{day}-#{year}\""
        else
          # TODO: show a message warning: ej. not op field choosen ...
          next if column_name.blank? or !conditions_op or !params[:conditions_value][key]
          next if conditions_op.blank? or params[:conditions_value][key].blank?
          conditions_value = params[:conditions_value][key]
          conditions_value = "%" + conditions_value + "%" if conditions_op == "=~"
          conditions_value = "\"" + conditions_value + "\"" if column_type == "string"
          
        end
        route = get_route(key)
        join_position = search_model_in_query(@actual_query, route)
  
        # jump if there're more than one condition but there aren't any condition type (or, and, ... )
        # TODO: show a message warning
        #raise "aqui" if !join_position[:conditions].empty? and (!params[:conditions_cond_type][key] or params[:conditions_cond_type][key].blank?)
  
        # add the condition
        params_type = params[:conditions_cond_type][key] if params[:conditions_cond_type]
        join_position[:conditions] << add_new_condition_for_query(column_name, conditions_op,
                                          conditions_value,  params_type)
      end # params[:conditions_column].each

    end # if params[:conditions_column] and (params[:conditions_op_string] or params...

    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"
  end
  
  def run_query
    init
    @actual_query = session[:actual_query]
    if @actual_query
      @ar_base = ActiveRecord::Base.connection.select_all(get_sql_for_query(@actual_query, @activerecord_columns))
      session[:ar_base] = @ar_base
    end
    render :partial => "run_query"
  end
  
  def run_query_txt
    @delimiter = params[:csv] ? ";": "\t"
    @ar_base = session[:ar_base]
    headers['Content-Type'] = "text/plain"
    headers['Content-Disposition'] = 'attachment; filename="query-export.'+ (params[:csv] ? "csv": "txt") + '"'
  end

  def run_query_excel
    @ar_base = session[:ar_base]
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="query-export.xls"'
  end

  
  def remove_condition
    @actual_query = session[:actual_query]
    route = get_route(params[:condition_model])
    cond_position = search_model_in_query(@actual_query, route)
    cond_position[:conditions].delete_at(params[:condition_index].to_i)
    cond_position[:conditions][0][:cond_type] = nil unless cond_position[:conditions].empty?
    init
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"
#    render :text => join_position.to_json
  end

  def remove_model
    @actual_query = session[:actual_query]
    route = get_route(params[:condition_model])
    delete_model_in_query(@actual_query, route)
    init
    logger.debug @actual_query.to_json
    @actual_query = nil and session[:actual_query] = nil if @actual_query.empty?
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"  
  end

  def show_model_column_condition
    model = params[:model]
    column = params[:column]
    init
    #logger.debug model
    #logger.debug column
    #logger.debug @activerecord_columns.to_json
    #logger.debug @activerecord_columns[model].to_json
    @c_type = @activerecord_columns[model][column]
    @key = params[:key]
    #@position = params[:deep] + "_" + params[:wide]
  end
end
