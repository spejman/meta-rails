# 
# xml_data_to_db.rb
# 
# Created on 03-oct-2007, 14:18:25
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require 'rexml/document'
include REXML

class MetaRailsError < Exception; end
class AttributeNotExist < MetaRailsError; end
class ClassNotExist < MetaRailsError; end
class RelationNotExist < MetaRailsError; end
class IdNotExist < MetaRailsError; end
class RelationsUnsolvable < MetaRailsError; end

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
            
            # Check for the relation cardinality
            proposed_klass_attr = is_a_relation? proposed_klass_attr, klass_name, klasses_struct
            names[klass_name][names[klass_name].rindex(klass_attr)] = proposed_klass_attr and next if proposed_klass_attr
            
            raise RelationNotExist, "Don't exist relation between #{proposed_klass_attr.singularize}/#{proposed_klass_attr} and #{klass_name}"
            
          end
          
          raise AttributeNotExist, "#{klass_attr} don't exists for the model #{klass_name} into the database" unless ( klasses_struct[klass_name]["class_attr"].keys + 
              klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]} ).include?(klass_attr)
        end
      end      
      return names
    end
    
    # Checks if the identifiers that are into the XML file are consistent
    def check_if_xml_is_consistent_with_its_ids(doc_root, klasses_struct)
      attr_with_ids = get_xml_model_attr_with_ids(doc_root, klasses_struct)
      model_ids = get_xml_model_ids(doc_root)
      
      attr_with_ids.each do |a_name, a_values|
        a_values.each do |a_value|
          raise IdNotExist, "Id #{a_value} don't exist for the model #{a_name}" if !model_ids[a_name] || !model_ids[a_name].include?(a_value)
        end
      end
    end

    # MAIN FUNCTION:
    #   - checks for integrity of the data.
    #   - creates the objects and saves them into the DB.
    #   - ATTENTION: don't checks for repeated data, if the same information exists
    #   in the database, it will duplicate it or break some uniq database restriction.
    # Returns the root object.
    def insert_xml_data_into_db(doc_root, klasses_struct)
      names = check_if_xml_is_consistent_with_db(doc_root, klasses_struct)
      check_if_xml_is_consistent_with_its_ids(doc_root, klasses_struct)
      
      objects_with_ids = {} # a double hash that stores all objects with defined ids ( h[object_name][object_id] --> object )
      parent = {} # a hash with all the actual object parents ( h[parent_name] --> parent_object )
      to_process = [] # a queue of {:obj, :xml, :parents} struct with the objects waiting to be processed.
      
      root_object = create_objects_from_xml(doc_root, klasses_struct, parent, to_process, objects_with_ids)
      
      # Some objects must be created before anothers in order to solve the relation ids
      # this iteration tries to solve all the relations
      actual_to_process = to_process; to_process = []
      while !actual_to_process.empty? do        
        actual_to_process.each do |struct_to_process|
          create_objects_from_xml(struct_to_process[:xml], klasses_struct, struct_to_process[:parent], to_process, objects_with_ids, struct_to_process[:obj])
        end
        raise RelationsUnsolvable, "Relations cannot be solved!" if (actual_to_process.collect{|a| a[:obj]} & to_process.collect{|a| a[:obj]}) == actual_to_process.collect{|a| a[:obj]}
        actual_to_process = to_process; to_process = []
      end
      
      return root_object
    end

    # Given an XML representation of a object, a struct with the classes (klasses_struct), the parent object (if exist),
    # a list of objects that can be related with its ids. Creates the object if all the relations can be solved,
    # otherwise includes itself to the to_process array using a struct like a hash with the keys:
    #   - :obj --> created object.
    #   - :xml --> document root with the XML representing the object.
    #   - :parent --> parent object.
    def create_objects_from_xml(doc_root, klasses_struct, parent, to_process, objects_with_ids, obj = nil)
      # Create the object
      obj = doc_root.name.classify.constantize.new unless obj
      
      # Assign the attributes
      doc_root.attributes.each do |a_name, a_value|
        # If is an Id index it and jump to next attribute
        if a_name == "id"
          objects_with_ids[doc_root.name] ||= {}
          objects_with_ids[doc_root.name][a_value] = obj
          obj.identifier = a_value
          next
        end

        # Check if relation, get it:
        #   if exists --> assign it
        #   else --> put into @to_proccess list and next
        if relation_name = is_a_relation?(a_name, doc_root.name, klasses_struct)
          #puts "#{relation_name} --> #{relation_name.singularize.camelize} --> #{a_value}"
          relation_type = klasses_struct[doc_root.name]["class_ass"].select {|ca| ca.values[0] == relation_name}.first.keys[0]
          relation_obj_ids = a_value.split # If there's more than one relation
          
          relation_obj_ids.each do |relation_obj_id|
           # puts "SUB #{relation_name} --> #{relation_name.singularize.camelize} --> #{relation_obj_id}"
            relation_obj = objects_with_ids[relation_name.singularize.camelize][relation_obj_id] if objects_with_ids[relation_name.singularize.camelize]
            # if exists the relation
            if relation_obj
            #  puts "RELATION OBJECT --> #{relation_name}"
              if relation_type == "belongs_to" || relation_type == "has_one"
                obj.send "#{relation_name}=".to_sym, relation_obj
              else
                rel_array = obj.send("#{relation_name}")
                rel_array.send("<<".to_sym, relation_obj) unless rel_array.include? relation_obj
              end

            else
              to_process << {:obj => obj, :xml => doc_root, :parent => parent.dup}
            end
          end
        # Check if normal attribute --> assign it
        else
          obj.send "#{a_name}=".to_sym, a_value
        end                        
      end
      
      # Check if some of the parents can be an attribute and make the relation
      parent.each do |parent_name, parent_obj|
        if relation_name = is_a_relation?(parent_name, doc_root.name, klasses_struct)
          relation_type = klasses_struct[doc_root.name]["class_ass"].select {|ca| ca.values[0] == relation_name}.first.keys[0]
          if relation_type == "belongs_to" || relation_type == "has_one"
              obj.send("#{relation_name}=".to_sym, parent_obj)
            else
              rel_array = obj.send("#{relation_name}")
              rel_array.send("<<".to_sym, parent_obj) unless rel_array.include? parent_obj
            end          
        end
      end
      
      obj.save
      
      # Add itself to the parents list till the recursive call is being executed.
      #parents[doc_root.name] = obj      
      parent = {}
      parent[doc_root.name] = obj
      # Process recursive all the child elements
      doc_root.each_element {|element| create_objects_from_xml(element, klasses_struct, parent, to_process, objects_with_ids) }      
      # Remove itself from the parents list once it returns from the recursive call.
      #parents.delete doc_root.name
      return obj
    end
    
    # PRIVATE METHODS
    private

    # Returns nil if attribute_name is not a klass_name relation given klasses_struct.
    # If is a relation, returns the name of the relation with the correct cardinality.
    def is_a_relation?(attribute_name, klass_name, klasses_struct)

      # Try a 1 relation
      proposed_klass_attr = attribute_name.underscore
      return proposed_klass_attr if klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]}.include?(proposed_klass_attr)
            
      # Try a n relation
      proposed_klass_attr = attribute_name.underscore.pluralize
      return proposed_klass_attr if klasses_struct[klass_name]["class_ass"].collect{|a| a.values[0]}.include?(proposed_klass_attr)

      # Is not a relation
      return nil
    end
    
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
    
    # Returns a hash with keys equal to the classes names and values equal to
    # an array of the class attributes.
    # If with some attribute it is not clear its cardinality, it puts the prefix
    # PLURAL_SINGULAR_UNKNOWN_PREFIX.
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
