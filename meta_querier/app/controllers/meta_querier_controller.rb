require "digest/md5"
require "fileutils"
require "meta_querier"
require "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/helpers/meta_querier_helper.rb"

include MetaQuerierHelper
include MetaRails::InferDbModel

class MetaQuerierController < ApplicationController

  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_querier/app/views/"
  
  layout "application", :except => ["run_query_txt", "run_query_excel"]
 
  # ActAsAuthenticated hook. If ActAsAuthenticated is installed as a plugin
  # and MetaQuerierUseActAsAuth don't exists or its value is true then:
  #   - Includes AuthenticatedSystem
  #   - Calls login_required unless logged_in? before each request.
  if File.exists? "#{RAILS_ROOT}/vendor/plugins/acts_as_authenticated"
    include AuthenticatedSystem
    before_filter :do_login_if_required
    def do_login_if_required
      login_required if (!defined?(MetaQuerierUseActAsAuth) or MetaQuerierUseActAsAuth) and !logged_in?
    end
  end

  # Inialization method
  #   - Checks if meta querier tables exists
  #   - Loads avariable profiles at @avariable_profiles
  #   - Creates @klasses_struct will all the profile related db data.
  #   - Fills @activerecord_classes, @activerecord_columns, @activerecord_associations global variables.
  def init
    #TODO: put as before_filter
    
    raise "Meta querier tables don't exist, run script/generate meta_querier_query_tables, rake db:migrate \
    and restart the Server" unless META_QUERIER_TABLES
    session[:profile] ||= "ALL"
    session[:profile] = params[:profile] if params[:profile]

    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}

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
  end

# ACTIONS

  # Creates a new empty actual_query
  def index
    init
    @actual_query = session[:actual_query]
    session[:my_query] ||= MetaQuerierQuery.new(:name => "Query #{Time.now}")
    @my_query = session[:my_query]

    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns) if session[:actual_query]
  end

# IMAGE GENERATION actions
  
  # Generates the image and redirects to the correct image path.
  def get_image
    init
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
      rav = MetaQuerier::RailsApplicationVisualizer.new({ :model_names => @model_names, :model_columns => @activerecord_columns,
                                                          :model_associations => @activerecord_associations,
                                                          :actual_model => params[:model] })    
      rav.output image_path
    end
    redirect_to image_filename
  end
  
  # Deletes all the models images cache.
  def clear_models_images_cache
    num_images = Dir["#{RAILS_ROOT}/public/images/meta_rails/meta_querier/*.png"].size
    Dir["#{RAILS_ROOT}/public/images/meta_rails/meta_querier/*.png"].each do |image_file|
      FileUtils.rm_f image_file
    end
    render :text => "Deleted #{num_images} images in models images cache"
  end

# QUERY MANAGEMENT actions (new, save, load ... )

  # (alias new_query) Clears the actual_query and creates a new empty one.
  def clear_query
    session[:actual_query] = nil
    session[:my_query] = MetaQuerierQuery.new(:name => "Query #{Time.now}", :history => true)
    @my_query = session[:my_query]
    init
    
    request.xhr? ? render(:partial => "make_query") : redirect_to(:action => "index")
  end
  alias new_query clear_query

  # Saves the actual_query
  def save_query
    init
    session[:actual_query] ||= []
    @actual_query = session[:actual_query]
    @my_query = session[:my_query]

    if params[:meta_querier_query]
      if @my_query.new_record?
        @meta_querier_query = MetaQuerierQuery.new(params[:meta_querier_query])
      else
        @meta_querier_query = session[:my_query]
        @meta_querier_query.update_attributes(params[:meta_querier_query])
      end
      @meta_querier_query.query = @actual_query
      @meta_querier_query.save!
      
      if params[:meta_querier_query_conditions]
        params[:meta_querier_query_conditions].keys.each do |mqqc_key|
          p_mqqc = params[:meta_querier_query_conditions][mqqc_key]
          next if (p_mqqc[:id].nil? && (p_mqqc[:variable] == "false"))
          
          if p_mqqc[:id]
            mqqc = MetaQuerierQueryCondition.find p_mqqc[:id]
            mqqc.destroy and next if (p_mqqc[:variable] == "false")
          else
            mqqc = MetaQuerierQueryCondition.new
          end
          mqqc.is_select = p_mqqc[:is_select] || false
          mqqc.description = p_mqqc[:description]
          mqqc.route = mqqc_key.split("___")[0]
          mqqc.position = mqqc_key.split("___")[1]
          mqqc.meta_querier_query = @meta_querier_query
          mqqc.save!
        end
      end
      list_queries
    else
      @query_conditions = get_conditions(@actual_query)
      render :partial => "save_query"
    end
  end
  
  # Loads and shows and edits requested query
  def edit_my_query
    query = MetaQuerierQuery.find params[:id]
    session[:my_query] = query
    session[:actual_query] = query.query
    @my_query = session[:my_query]
    make_query
  end

  # Deletes requested query
  def delete_my_query
    query = MetaQuerierQuery.find params[:id]
    query.destroy
    list_queries
  end

  # Shows a list of all the queries. Depending of params[:history] == true or false
  # shows the historic queries or not.
  def list_queries
    init
    session[:actual_query] ||= []
    @actual_query = session[:actual_query]
    @my_query = session[:my_query]
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)
    opts = {}
    opts[:conditions] = [ "history = ?", params[:history] ] if params[:history]
    opts[:order] = "created_at desc"
    @queries = MetaQuerierQuery.find :all, opts
    render :partial => "my_queries"
  end
      
# BUILD & EDIT query actions

  # Main build query action that constructs the actual_query struct based on
  # form data recieved. Renders "_make_query" partial
  def make_query
    init
    session[:actual_query] ||= []
    @actual_query = session[:actual_query]
    @my_query = session[:my_query]    
    if params[:query]      
      select_columns = add_columns_select_for_query @activerecord_columns[params[:query][:model]].keys
      @actual_query << add_new_model_for_query(params[:query][:model], select_columns, 0, 0) if params[:query][:model]
    end
    
    # Select attribute checks. ATENTION: must be done before get join conditions
    # otherwise will unselect the attributes of new created joins.
    if params[:select_columns]
      each_model_with_route(@actual_query) do |actual_q, route|
        if params[:select_columns][route]
          actual_q[:select].keys.each do |column_name|
            actual_q[:select][column_name] = params[:select_columns][route].include? column_name
          end
        else
          actual_q[:select].keys.each {|column_name| actual_q[:select][column_name] = false } unless actual_q[:select].empty?
        end
      end
    end
    
    
    # Get join conditions
    if params[:join]
      params[:join].each do |key, value|
        next if value.blank?
        route = get_route(key)
        join_position = search_model_in_query(@actual_query, route)

        # Check for selected columns
        select_columns = add_columns_select_for_query @activerecord_columns[value].keys
        # Get deep and wide
        new_join_deep = join_position[:deep]+1
        new_join_wide = (join_position[:join].collect {|j| j[:wide]}.max + 1 unless join_position[:join].empty?) || 0

        # Add join position to the structure
        join_position[:join] << add_new_model_for_query(value, select_columns, new_join_deep, new_join_wide, params[:join_type][key])
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
          conditions_value = adecuate_conditions_value(params[:conditions_value][key], conditions_op, column_type)         
        end
        route = get_route(key)        
        join_position = search_model_in_query(@actual_query, route)
  
        # jump if there're more than one condition but there aren't any condition type (or, and, ... )
        # TODO: make the jump condition
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
   
  # Removes a condition from the actual_query struct.
  # Renders "_make_query" partial.
  def remove_condition
    @actual_query = session[:actual_query]
    @my_query = session[:my_query]
    # Search the position to be removed
    route = get_route(params[:condition_model])
    cond_position = search_model_in_query(@actual_query, route)
    # Remove the condition and puts to nil the first condition (if we removed
    # the first condition then the second will be the first but without :cond_type).
    cond_position[:conditions].delete_at(params[:condition_index].to_i)
    cond_position[:conditions][0][:cond_type] = nil unless cond_position[:conditions].empty?
    init
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"
  end

  # Removes a model from the actual_query struct.
  # Renders "_make_query" partial.
  def remove_model
    @actual_query = session[:actual_query]
    @my_query = session[:my_query]    
    route = get_route(params[:condition_model])
    delete_model_in_query(@actual_query, route)
    init
    logger.debug @actual_query.to_json
    @actual_query = nil and session[:actual_query] = nil if @actual_query.empty?
    @q_sql = get_sql_for_query(@actual_query, @activerecord_columns)

    render :partial => "make_query"  
  end

  # RJS that shows a specific model condition form 
  # depending on column data type
  def show_model_column_condition
    model = params[:model]
    column = params[:column]
    init

    @c_type = @activerecord_columns[model][column]
    @key = params[:key]
  end

# RUN QUERY actions

  # Runs saved query. If the query has varible conditions calls choose_conditions_for_run_query
  # otherwise runs the query and shows the HTML result (calling run_query).
  def run_my_query
    query = MetaQuerierQuery.find params[:id]
    session[:my_query] = query
    session[:actual_query] = query.query
    if query.meta_querier_query_conditions.empty?
      run_query
    else
      choose_conditions_for_run_query
    end
  end
  
  # Shows a form with for filling the defined query variable conditions,
  # when filled it runs the resulting query.
  def choose_conditions_for_run_query
    init
    @actual_query = session[:actual_query]
    if params[:meta_querier_query_conditions]
      params[:meta_querier_query_conditions].keys.each do |mqqc_key|
        route = get_route(mqqc_key.split("___")[0])
        position = mqqc_key.split("___")[1].to_i
        node = search_model_in_query(@actual_query, route)
        node[:conditions][position][:value] = adecuate_conditions_value(params[:meta_querier_query_conditions][mqqc_key],
                                                  node[:conditions][position][:op],
                                                  @activerecord_columns[node[:model]][node[:conditions][position][:column]].to_s)
      end
      run_query
    else
      @query = session[:my_query]
      render :partial => "choose_conditions_for_run_query", :layout => "run_query"
    end
  end

  # Returns query results in HTML
  def run_query
    init
    @actual_query = session[:actual_query]
    session[:my_query].query = @actual_query
    session[:my_query].save if session[:my_query].history
    if @actual_query
      @ar_base = ActiveRecord::Base.connection.select_all(get_sql_for_query(@actual_query, @activerecord_columns))
      session[:ar_base] = @ar_base
    end
    render :partial => "run_query", :layout => "run_query"
  end
  
  # Returns query results in  txt (csv or tab separated values)
  def run_query_txt
    @delimiter = params[:csv] ? ";": "\t"
    @ar_base = session[:ar_base]
    headers['Content-Type'] = "text/plain"
    headers['Content-Disposition'] = 'attachment; filename="query-export.'+ (params[:csv] ? "csv": "txt") + '"'
  end

  # Returns query results in  XML for excel
  def run_query_excel
    @ar_base = session[:ar_base]
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="query-export.xls"'
  end

end
