# 
# xml_data_to_db.rb
# 
# Created on 03-oct-2007, 14:18:25
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'rexml/document'

class MetaRailsError < Exception; end

module MetaRails
  
  
  module XmlDataToDb

    def get_xml_model_names_and_attributes(doc_root, names = {})
      names[doc_root.name] ||= []
      names[doc_root.name] += doc_root.attributes.keys.collect {|a| a.underscore }
      names[doc_root.name].uniq!
  
      doc_root.each_element {|element| get_xml_model_names_and_attributes(element, names) }
  
      return names
    end

    def check_if_xml_is_consistent_with_db(doc_root, klasses_struct)
      names = get_xml_model_names_and_attributes(doc_root)
      names.each do |klass_name, klass_attrs|
        raise MetaRailsError, "#{klass_name} don't exists into the database" unless klasses_struct[klass_name]
        klass_attrs.each do |klass_attr|
          next if klass_attr == "id"
          raise MetaRailsError, "#{klass_attr} don't exists for the model #{klass_name} into the database" \
            unless ( klasses_struct[klass_name]["class_attr"].keys + 
                klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]} ).include?(klass_attr)
        end
      end
    end
    
  end

end
