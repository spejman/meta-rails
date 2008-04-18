require "#{File.dirname(__FILE__)}/../test_helper"

class MetaScaffoldModelsTest < ActionController::IntegrationTest
  # fixtures :your, :models

  # Replace this with your real tests.
  def test_index
    get "/meta_scaffold_info"
    assert_response :success
    assert_not_nil assigns(:klasses_struct)
    assigns(:klasses_struct).keys.sort.each do |model_name|
      get "/meta_scaffold_models/#{model_name.pluralize.underscore}"
      assert_response :success, "Error en /meta_scaffold_models/#{model_name.pluralize.underscore}"
    end
  end

  def test_change_profile
    get "/meta_scaffold_info"
    assert_response :success
    assert_not_nil assigns(:klasses_struct)
    assigns(:klasses_struct).keys.sort.each do |model_name|
      default_profile = "ALL"
      bad_profile = "no existe"
      good_profiles = Dir[RAILS_ROOT + "/db/metarails/*.yml"].collect {|pr| File.basename(pr)[0..-5]}
  
      post "/meta_scaffold_models/#{model_name.pluralize.underscore}", :profile => bad_profile
      assert_response :success, "Change to BAD profile error /meta_scaffold_models/#{model_name.pluralize.underscore}?profile=#{bad_profile}"
      assert_equal "Profile #{bad_profile} doesn't exist using default profile #{default_profile}", flash[:notice]
      assert_equal "ALL", session[:profile]
  
      good_profiles.each do |good_profile|
        post "/meta_scaffold_models/#{model_name.pluralize.underscore}", :profile => good_profile 
        assert_response :success, "Change to good profile error /meta_scaffold_models/#{model_name.pluralize.underscore}?profile=#{good_profile}"
        assert_equal "Profile changed", flash[:notice]
        assert_equal good_profile, session[:profile]      
      end
    end
  end

end
