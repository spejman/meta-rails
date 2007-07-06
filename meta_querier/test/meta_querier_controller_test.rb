require File.dirname(__FILE__) + '/../../../../test/test_helper'
require 'meta_querier_controller'
require 'infer_db_model'
include MetaRails::InferDbModel

# Re-raise errors caught by the controller.
class MetaQuerierController; def rescue_action(e) raise e end; end

class MetaQuerierControllerTest < Test::Unit::TestCase
  def setup    
    @controller = MetaQuerierController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_not_nil assigns(:klasses_struct)
  end

  def test_klass_struct_generation
    assert klass_struct.size < ActiveRecord::Base.connection.tables.size, "More struct models than database tables"
  end

  def test_query_all_models
    klass_struct.each do |model_name, model_details|
      test_session = {}
      xhr :get, :clear_query, nil, test_session
      assert_response :success
      assert_template "_make_query"

      assert session[:actual_query].nil?
      assert_not_nil session[:my_query]
      assert session[:my_query].new_record?

      params_1 = {  :commit=>"Choose begin model",
                  :query => {"model"=> model_name }
                }    
      do_request_make_query(params_1, test_session)
      assert session[:actual_query][0][:model] == model_name
      
      assert session[:actual_query][0][:select].size == model_details["class_attr"].size,
            "Different number of attributes in actual_query than in klass_struct for model #{model_name}"
            
      # Test simple query Only query if has attributes
      unless model_details["class_attr"].empty?
        # Run the query, automatically saves it
        xhr :get, :run_query, nil, session
        assert_response :success
        assert_template "_run_query"
#        assert_equal expected_actual_query, session[:actual_query]
        assert_not_nil session[:my_query]
        assert !session[:my_query].new_record?

        # Delete saved query
        q_id = session[:my_query].id
        xhr :get, :delete_my_query, {:id => q_id}, session
        assert_response :success
        assert_template "_my_queries"
        begin; MetaQuerierQuery.find(q_id); assert false, "Query not deleted"
        rescue ActiveRecord::RecordNotFound; assert true; end
      end

    
    end
  end

  def test_change_profile
    default_profile = "ALL"
    bad_profile = "no existe"
    good_profiles = Dir[RAILS_ROOT + "/db/metarails/*.yml"].collect {|pr| File.basename(pr)[0..-5]}

    post :index, :profile => bad_profile
    assert_response :success
    assert_equal "Profile #{bad_profile} doesn't exist using default profile #{default_profile}", flash[:notice]
    assert_equal "ALL", session[:profile]

    good_profiles.each do |good_profile|
      post :index, :profile => good_profile 
      assert_response :success
      assert_equal "Profile changed", flash[:notice]
      assert_equal good_profile, session[:profile]  
    end
  end
  
  def do_request_make_query(params, session)
    xhr :post, :make_query, params, session
    assert_response :success
    assert_template "_make_query"
  end
  
  def tmp_test_create_and_run_query(test_session = {})
    get :index
    assert_response :success

    
    xhr :get, :clear_query, nil, test_session
    assert_response :success
    assert_template "_make_query"
    
    assert session[:actual_query].nil?
    assert_not_nil session[:my_query]
    assert session[:my_query].new_record?
    
    params_1 = {  :commit=>"Choose begin model",
                  #"action"=>"make_query", "controller"=>"meta_querier", 
                  :query => {"model"=>"Sense"}
                }    
    do_request_make_query(params_1, test_session)
    
    params_2 = { :commit =>"Add join",
                 :join_type => {"Sense_0"=>"inner"},
                 # "action"=>"make_query", "controller"=>"meta_querier",
                 :join => {"Sense_0"=>"Definition"}
                }

    do_request_make_query(params_2, test_session)
    
    params_3 = {:conditions_c_type => {"Sense_0__Definition_0"=>"string"},
              :conditions_column => {"Sense_0__Definition_0"=>"text"}, 
              :commit => "Add%2520join",
              :conditions_op_string => {"Sense_0__Definition_0"=>"=~"}, 
              :conditions_value => {"Sense_0__Definition_0"=>"dicho de"}, 
              :join_type => {"Sense_0__Definition_0"=>"inner", "Sense_0"=>"inner"}, 
              :select_columns => {"Sense_0__Definition_0"=>["text"]}, 
              :action => "make_query", :controller => "meta_querier", 
              :conditions_value_date => {"Sense_0__Definition_0(1i)"=>"2007", 
                "Sense_0__Definition_0(2i)"=>"7", "Sense_0__Definition_0(3i)"=>"3"}, 
              :conditions_op_integer => {"Sense_0__Definition_0"=>""},
              :join =>{"Sense_0__Definition_0"=>"", "Sense_0"=>""}
              }

    do_request_make_query(params_3, test_session)
    
    expected_actual_query = [{:select=>{"synset"=>false, "inherit"=>false},
                              :model=>"Sense",
                              :join=>
                               [{:select=>{"text"=>true},
                                 :model=>"Definition",
                                 :join=>[],
                                 :conditions=>
                                  [{:value=>"\"%dicho de%\"",
                                    :cond_type=>nil,
                                    :column=>"text",
                                    :op=>"=~"}],
                                 :wide=>0,
                                 :deep=>1,
                                 :join_type=>"inner"}],
                              :conditions=>[],
                              :wide=>0,
                              :deep=>0,
                              :join_type=>nil}]
    
    assert_equal expected_actual_query, session[:actual_query]
    assert_not_nil session[:my_query]
    assert session[:my_query].new_record?
    
    # Run query
    xhr :get, :run_query, nil, session

    assert_response :success
    assert_template "_run_query"

    assert_equal expected_actual_query, session[:actual_query]
    assert_not_nil session[:my_query]
    assert !session[:my_query].new_record?
        
  end

  def tmp_test_create_and_run_query_and_save
    test_session = {}
    test_create_and_run_query(test_session)
    xhr :get, :save_query, nil, session

    assert_response :success
    assert_template "_save_query"
    
  end

  def test_get_image
    get :get_image
    
    image_filename = "/images/meta_rails/meta_querier/" + Digest::MD5.new(assigns(:model_names).join("#")).to_s + ".png"
    assert_redirected_to image_filename
    assert File.exists?(File.join("#{RAILS_ROOT}/public", image_filename))
    
    #TODO: Test changing models
    
  end
end
