# 
# xml_data_to_db.rb
# 
# Created on 03-oct-2007, 14:18:25
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'rexml/document'

class MetaRailsError < Exception; end
class AttributeNotExist < MetaRailsError; end
class ClassNotExist < MetaRailsError; end
class RelationNotExist < MetaRailsError; end
class IdNotExist < MetaRailsError; end

module MetaRails
  
  
  module XmlDataToDb

    PLURAL_SINGULAR_UNKNOWN_PREFIX = "METARAILS_UNKNOWN_PS_"
    
    # Checks if the XML root document given at doc_root is consistent with the
    # database structure.
    # 
    # doc_root must be created like Document.new(xml_data_file).root
    # 
    # Returns the result of get_xml_model_names_and_attributes(doc_root) if
    # no problem found, otherwise can return ClassNotExist or AttributeNotExist
    # exceptions.
    # Solves the PLURAL_SINGULAR_UNKNOWN_PREFIX attributes getting the correct 
    # association name in plural or singular.
    def check_if_xml_is_consistent_with_db(doc_root, klasses_struct)
      names = get_xml_model_names_and_attributes(doc_root)
      names.each do |klass_name, klass_attrs|
        raise ClassNotExist, "#{klass_name} don't exists into the database" unless klasses_struct[klass_name]
        klass_attrs.each do |klass_attr|
          next if klass_attr == "id"
          
          if klass_attr[0..PLURAL_SINGULAR_UNKNOWN_PREFIX.size-1] == PLURAL_SINGULAR_UNKNOWN_PREFIX
            
            proposed_klass_attr = klass_attr.gsub(Regexp.new("\\A#{PLURAL_SINGULAR_UNKNOWN_PREFIX}"), "")
            
            # Try a 1 relation
            proposed_klass_attr = proposed_klass_attr.underscore
            names[klass_name][names[klass_name].rindex(klass_attr)] = proposed_klass_attr and next \
            if klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]}.include?(proposed_klass_attr)
            
            # Try a n relation
            proposed_klass_attr = proposed_klass_attr.underscore.pluralize
            names[klass_name][names[klass_name].rindex(klass_attr)] = proposed_klass_attr and next \
            if klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]}.include?(proposed_klass_attr)
            
            raise RelationNotExist, "Don't exist relation between #{proposed_klass_attr.singularize}/#{proposed_klass_attr} and #{klass_name}"
            
          end
          
          raise AttributeNotExist, "#{klass_attr} don't exists for the model #{klass_name} into the database" unless ( klasses_struct[klass_name]["class_attr"].keys + 
              klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]} ).include?(klass_attr)
        end
      end      
      return names
    end
    
    # Checks if the identifiers that are into the XML file are consistent with
    #
    def check_if_xml_is_consistent_with_its_ids(doc_root, klasses_struct)
      attr_with_ids = get_xml_model_attr_with_ids(doc_root, klasses_struct)
      model_ids = get_xml_model_ids(doc_root)
      
      attr_with_ids.each do |a_name, a_values|
        a_values.each do |a_value|
          raise IdNotExist, "Id #{a_value} don't exist for the model #{a_name}" if !model_ids[a_name] || !model_ids[a_name].include?(a_value)
        end
      end
    end
    
    def insert_xml_data_into_db(doc_root, klasses_struct)
      names = check_if_xml_is_consistent_with_db(doc_root, klasses_struct)
      check_if_xml_is_consistent_with_its_ids(doc_root, klasses_struct)
      
    end

    private

    # Returns a hash with all the attributes that are a ensemble of ids.
    def get_xml_model_attr_with_ids(doc_root, klasses_struct, attr_with_ids = {})
      relations = klasses_struct[doc_root.name]["class_ass"].collect{|a| a.values[0]}
      doc_root.attributes.select {|a_name, a_value| relations.include? a_name.underscore }.each do |a_name, attribute|
        a_name = a_name.underscore.singularize; attr_with_ids[a_name] ||= []
        attr_with_ids[a_name] += attribute.value.split
        attr_with_ids[a_name].uniq!
      end
      
      doc_root.each_element {|element| get_xml_model_attr_with_ids(element, klasses_struct, attr_with_ids) }
      
      return attr_with_ids
    end
    
    # Return all the models that have a id.
    def get_xml_model_ids(doc_root, model_ids = {})
      id_attr = doc_root.attributes.select {|a_name, a_value| a_name == "id"}
      raise MetaRailsError, "Element with more than one id #{doc_root.name}" if id_attr.size > 1
      
      unless id_attr.empty?
        model_ids[doc_root.name.underscore] ||= []
        model_ids[doc_root.name.underscore] << id_attr.first[1].value
      end
      
      doc_root.each_element {|element| get_xml_model_ids(element, model_ids) }
      
      model_ids
    end
    
    def get_xml_model_names_and_attributes(doc_root, names = {})
      names[doc_root.name] ||= []
      names[doc_root.name] += doc_root.attributes.keys.collect {|a| a.underscore }
      names[doc_root.name] += doc_root.elements.collect do |e| 
        if doc_root.elements.select {|e2| e2.name == e.name}.size > 1
          e.name.underscore.pluralize
        else
          PLURAL_SINGULAR_UNKNOWN_PREFIX + e.name
        end        
      end
      names[doc_root.name].uniq!
  
      doc_root.each_element {|element| get_xml_model_names_and_attributes(element, names) }
  
      return names
    end

    
  end

end
