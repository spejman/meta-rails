require 'test/unit'
require File.join(File.dirname(__FILE__), "../lib/incremental_model.rb")

      # { class_name_1 => {"class_attr"=>{"attr_name_1"=>"attr_type_1", ...},
      #                   "class_ass" => [ {"ass_type_1" => "relation_1"}, {..}, ... ] }
      # 
      # Ej: { "lexical_entry" => { "class_attr" => {"created_on"=>"date", "name"=>"string"}, 
      #           "class_ass" => [ {"has_many"=>"senses"}, {"has_many"=>"syntactic_behaviours"},
      #                            {"belongs_to"=>"lexicon"}]
      #                          },
      #       ... }


# Must set before requiring generator libs.
tmp_dir="#{File.dirname(__FILE__)}/tmp"
if defined?(RAILS_ROOT)
  RAILS_ROOT.replace(tmp_dir)
else
  RAILS_ROOT=tmp_dir
end
Dir.mkdir(RAILS_ROOT) unless File.exists?(RAILS_ROOT)
  
#$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../../lib"
require 'rails_generator'
require File.join(File.dirname(__FILE__), 'generator_test_helper.rb')

class MetaScaffoldTest < Test::Unit::TestCase
  
  include GeneratorTestHelper

  def setup
    ActiveRecord::Base.pluralize_table_names = true
    Dir.mkdir("#{RAILS_ROOT}/app") unless File.exists?("#{RAILS_ROOT}/app")
    Dir.mkdir("#{RAILS_ROOT}/app/views") unless File.exists?("#{RAILS_ROOT}/app/views")
    Dir.mkdir("#{RAILS_ROOT}/app/views/layouts") unless File.exists?("#{RAILS_ROOT}/app/views/layouts")
    Dir.mkdir("#{RAILS_ROOT}/config") unless File.exists?("#{RAILS_ROOT}/config")
    Dir.mkdir("#{RAILS_ROOT}/db") unless File.exists?("#{RAILS_ROOT}/db")
    Dir.mkdir("#{RAILS_ROOT}/test") unless File.exists?("#{RAILS_ROOT}/test")
    Dir.mkdir("#{RAILS_ROOT}/test/fixtures") unless File.exists?("#{RAILS_ROOT}/test/fixtures")
    Dir.mkdir("#{RAILS_ROOT}/public") unless File.exists?("#{RAILS_ROOT}/public")
    Dir.mkdir("#{RAILS_ROOT}/public/stylesheets") unless File.exists?("#{RAILS_ROOT}/public/stylesheets")
    File.open("#{RAILS_ROOT}/config/routes.rb", 'w') do |f|
      f<<"ActionController::Routing::Routes.draw do |map|\n\nend\n"
    end
  end  

  def teardown
    FileUtils.rm_rf "#{RAILS_ROOT}/app"
    FileUtils.rm_rf "#{RAILS_ROOT}/test"
    FileUtils.rm_rf "#{RAILS_ROOT}/config"
    FileUtils.rm_rf "#{RAILS_ROOT}/db"
    FileUtils.rm_rf "#{RAILS_ROOT}/public"
  end  
  
  # incrementa_model lib tests
  def test_incremental_model_empty_or_equal
    # Empty test
    db_classes = {}
    assert changes_to_apply(db_classes, db_classes).empty?

    # Equal test
    db_classes = {"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"} }}
    assert_equal({"test_class_1" => {} } , changes_to_apply(db_classes, db_classes))

  end
  
  def test_incremental_model_new_class
    db_classes = {"test_class_2" => {} }
    new_classes = {"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"}} }
    assert_equal({"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"}}}, changes_to_apply(db_classes, new_classes))    
  end
  
  def test_incremental_model_new_attr
    
    db_classes = {"test_class_1" => {} }
    new_classes = {"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"}} }
    assert_equal({"test_class_1" => {:add => {"created_on"=>"date", "name"=>"string"}}}, changes_to_apply(db_classes, new_classes))
    
  end

  def test_incremental_model_remove_attr
    
    db_classes = {"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"} }}
    new_classes = {"test_class_1" => {} }
    
    assert_equal({"test_class_1" => {:remove => ["created_on", "name"] }}, changes_to_apply(db_classes, new_classes))
    
  end

  def test_incremental_model_modify_attr
    
    db_classes = {"test_class_1" => {:class_attr => {"created_on"=>"date", "name"=>"string"} }}
    new_classes = {"test_class_1" => {:class_attr => {"created_on"=>"string", "name"=>"integer"}} }
    assert_equal({"test_class_1" => {:modify => {"created_on"=>"string", "name"=>"integer"}} }, changes_to_apply(db_classes, new_classes))
    
  end
  
  
end
