# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Stores Forms
#
# Attributes:
#   * name => string
#   * description => string
#   * meta_forms_form_table_id => integer
#   * created_at, updated_at => datetime

class MetaFormsForm < ActiveRecord::Base
  set_table_name 'meta_forms_forms'
  belongs_to :meta_forms_form_table, :dependent => :delete_all # initial table
  
  alias_attribute :initial_table, :meta_forms_form_table
  
end
