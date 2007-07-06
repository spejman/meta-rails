require 'test/unit'
require File.dirname(__FILE__) + '/../../../../test/test_helper'

class MetaQuerierTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_installation
    assert File.exist?(File.join(RAILS_ROOT, "public/stylesheets/meta_rails/meta_querier.css"))
    assert File.exist?(File.join(RAILS_ROOT, "public/images/meta_rails/cross.png"))
    assert File.exist?(File.join(RAILS_ROOT, "public/images/meta_rails/indicator.gif"))
    assert File.exist?(File.join(RAILS_ROOT, "public/images/meta_rails/add.png"))
    assert File.exist?(File.join(RAILS_ROOT, "public/images/meta_rails/remove.png"))
    assert File.exist?(File.join(RAILS_ROOT, "public/images/meta_rails/meta_querier"))    
  end
end
