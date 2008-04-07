# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Stores Attribute of Forms Tables 
#
# Attributes:
#   * attr_name => string
#   * name => string
#   * description => string
#   * hidden => bool
#   * compulsory => bool
#   * default_value => string
#   * field_type => string
#   * meta_forms_form_table_id => integer
#   * created_at, updated_at => datetime

class MetaFormsAttribute < ActiveRecord::Base
  set_table_name 'meta_forms_attributes'
  belongs_to :meta_forms_form_table
  
  alias_attribute :form_table, :meta_forms_form_table

end
