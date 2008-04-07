# MetaForms
require File.join RAILS_ROOT, "vendor", "plugins", "meta_rails_common", "lib", "meta_rails_common.rb"

# Load models
Dir[File.dirname(__FILE__) + "/../app/models/meta_forms*.rb"].each {|f| require f}

# Check if MetaForms model tables exist in the DB
META_FORMS_TABLES = MetaFormsForm.table_exists? && MetaFormsFormTable.table_exists? && MetaFormsAttribute.table_exists?
