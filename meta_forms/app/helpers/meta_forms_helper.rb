# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

module MetaFormsHelper


def variable_name(table_name, parent_objects_names = [], number = 0)
    str = ""
    str = parent_objects_names.collect {|pon| pon.underscore.singularize}.join("_") + "_" unless parent_objects_names.empty?
    str + table_name.underscore.singularize + "_#{number}"
end

def instantiate_form_table_object(table_name, id, parent_objects_names = [], number = 0)
  object_name = variable_name table_name, parent_objects_names, number
  object = eval("@#{object_name} = table_name.classify.constantize.find #{id}")
end

  
def instantiate_all_variables(form, parent_id)
  parent_object = instantiate_form_table_object(form.initial_table.table_name, parent_id)
  parent_objects_names = [variable_name(form.initial_table.table_name)]
  
  recursive_instantiate_variables(form.initial_table, parent_objects_names, parent_object)
  
  return parent_object
end  

def recursive_instantiate_variables(form_table, parent_objects_names, parent_object)
  
  form_table.child_tables.each do |c_table|
    c_table_name = c_table.table_name.underscore
    acc_method = parent_object.methods.select {|m| m == c_table_name || m == c_table_name.pluralize}.first
    related_objects = [parent_object.send(acc_method)].flatten # related_object is always a array independant of 1 o many relation.
    related_objects.each_with_index do |related_obj, index|
        current_object = instantiate_form_table_object(c_table.table_name, related_obj.id, parent_objects_names, index)
        recursive_instantiate_variables(c_table, (parent_objects_names + [(variable_name c_table.table_name, parent_objects_names, index)]), current_object)
    end    
  end
end

def get_relation_method_name(parent_object, relation_table_name)
  relation_table_name = relation_table_name.underscore
  if parent_object.methods.select {|m| m == relation_table_name.pluralize }.empty?  
    return relation_table_name
  else
    return relation_table_name.pluralize
  end
end

def is_plural?(word)
  word.singularize != word
end

end