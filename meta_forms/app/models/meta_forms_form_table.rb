# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Stores Forms Tables and it's caracteristics
#
# Attributes:
#   * table_name => string
#   * name => string
#   * description => string
#   * hidden => bool
#   * default_id_value => integer
#   * meta_forms_form_table_id => integer
#   * created_at, updated_at => datetime

class MetaFormsFormTable < ActiveRecord::Base
  set_table_name 'meta_forms_form_tables'
  has_one :meta_forms_form # if is the initial table has one form.
  belongs_to :meta_forms_form_table # parent table (if initial table --> null)
  has_many :meta_forms_form_tables, :dependent => :delete_all # child tables  
  has_many :meta_forms_attributes, :dependent => :delete_all # own attributes

  alias_attribute :parent_table, :meta_forms_form_table
  alias_attribute :table_attributes, :meta_forms_attributes
  alias_attribute :child_tables, :meta_forms_form_tables
  
  def before_save
    self.name ||= self.table_name.humanize    
  end
  
  
  # Adds the actual profile avaliable attributes to the form_table object.
  def add_forms_attributes(avaliable_attributes)
    logger.debug "add_avaliable_attributes INIT"
    logger.debug avaliable_attributes.to_json
    logger.debug "add_avaliable_attributes first cond"
    avaliable_attributes.keys.each do |att_name|
      attr = {:attr_name => att_name,
        :field_type => avaliable_attributes[att_name].to_s,
        :meta_forms_form_table_id => self.id }
      MetaFormsAttribute.create(attr)
    end
  end
    
  
  def fech_default_value
    table_name.classify.constantize.find default_id_value if default_id_value && default_id_value > 0
  end
  
end
