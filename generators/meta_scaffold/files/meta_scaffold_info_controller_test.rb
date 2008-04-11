require File.dirname(__FILE__) + '/../test_helper'
require 'meta_scaffold_info_controller'
RAILS_ROOT = File.dirname(__FILE__) + '/../../' unless defined? RAILS_ROOT

# Re-raise errors caught by the controller.
class MetaScaffoldInfoController; def rescue_action(e) raise e end; end

class MetaScaffoldInfoControllerTest < Test::Unit::TestCase
  def setup    
    @controller = MetaScaffoldInfoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_index
    get :index
    assert_response :success
    assert_not_nil assigns(:klasses_struct)
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

end
