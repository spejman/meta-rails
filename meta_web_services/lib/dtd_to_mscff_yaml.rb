#require "rubygems"
#require "active_support"

RESERVED_MIGRATION_WORDS = ["id"]

def dtd_to_mscff_yaml(filename)
  file_content = File.open(filename, "r").readlines.join
  
  elements = file_content.scan(/<!ELEMENT (\/?[^\>]+)\>/)
  elements = elements.flatten.each {|v| v.gsub!("\n", " "); v.gsub!(/\(|\)|,/, " ")}

  h_yaml = {}
  elements.each do |element|
    element = element.split
    h_yaml[element[0]] ||= {}
    h_yaml[element[0]]["class_ass"] = element[1..-1].collect do |relation|
      next if relation == "EMPTY" # case like <!ELEMENT DC EMPTY>
      case relation[-1].chr
        when "*"
          {"has_many" => relation[0..-2]}
        when "+"
          {"has_many" => relation[0..-2]}
        when "?"
          {"has_one" => relation[0..-2]}
        else
          {"has_one" => relation[0..-1]}
#          raise "Unable to determine arity of [#{element[0]}] --> [#{relation}]"
        end
    end
    # if relation == EMPTY, h_yaml[element[0]]["class_ass"] == [nil],
    # compact it to become h_yaml[element[0]]["class_ass"] == []
    h_yaml[element[0]]["class_ass"].compact!
  end
 
  attributes = file_content.scan(/<!ATTLIST (\/?[^\>]+)\>/)
  attributes = attributes.flatten.each {|v| v.gsub!("\n", " ")}
  attributes.each do |attribute|
    attribute = attribute.split
    raise "Attibute [#{attribute}] of non existent element [#{attribute[0]}]" unless h_yaml[attribute[0]]
    attr_groups = [] # Group array in 3 positions for each atrribute [name, type, conditions]
    attribute[1..-1].each_with_index {|grouping, i| attr_groups << [] if (i%3) == 0; attr_groups[-1] << grouping }
    h_yaml[attribute[0]]["class_attr"] ||= {}
    attr_groups.each do |att_definition|
      next if RESERVED_MIGRATION_WORDS.include? att_definition[0]
      case att_definition[1]
        when "CDATA"
          h_yaml[attribute[0]]["class_attr"][att_definition[0]] = :string
        when "ID", "IDREF"
          # If exists a class with this name then belongs_to it TODO: or has_one?
          if h_yaml[att_definition[0]]
            h_yaml[attribute[0]]["class_ass"] << {"belongs_to" => att_definition[0]}
          else
            h_yaml[attribute[0]]["class_attr"][att_definition[0]] = :integer
          end
        when "IDREFS"
          # If exists a class with this name then has_many
          if h_yaml[att_definition[0]]
            h_yaml[attribute[0]]["class_ass"] << {"has_many" => att_definition[0]}
          else
            #TODO: this must raise an error because is unable to determite the relation!!
            #raise "Unable to determine the relation of #{attribute[0]} with [#{att_definition[0]}]"
            # Now if don't exists the class of the relation, then create de attribute as a string.
            h_yaml[attribute[0]]["class_attr"][att_definition[0]] = :string
          end
      end
    end
  end

  return h_yaml
end

  #TODO: move this method to ../generators/meta_scaffold/meta_scaffold_generator.rb
  def add_relations_to_klasses(klasses)
    klasses.each do |klass_name, klass_info|
      #puts "* " + klass_name
      # getting classes related with has_many
      klass_info["class_ass"].select{|r| r["has_many"]}.map{|r| r.values}.flatten.each do |t_klass|
        #puts "--> " + t_klass
        #puts ""
        target_klass = check_mode_klass_exists(klasses, t_klass, klass_name)

        if klasses[target_klass]["class_ass"].select{|r| r["has_many"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"].delete( {"has_many" => klass_name})
            klasses[klass_name]["class_ass"].delete( {"has_many" => target_klass})
            klasses[target_klass]["class_ass"] << {"has_and_belongs_to_many" => klass_name}
            klasses[klass_name]["class_ass"] << {"has_and_belongs_to_many" => target_klass}
        # TODO: make a special case with has_one
        # check if target class must have belongs_to
        elsif !klasses[target_klass]["class_ass"].select{|r| r["belongs_to"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"] << { "belongs_to" => klass_name }
            #puts "Added #{klass_name} to #{target_klass}"
        end
      end
      
      klass_info["class_ass"].select{|r| r["has_one"]}.map{|r| r.values}.flatten.each do |t_klass|
        target_klass = check_mode_klass_exists(klasses, t_klass, klass_name)
        
        if !klasses[target_klass]["class_ass"].select{|r| r["belongs_to"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"] << { "belongs_to" => klass_name }
            #puts "Added #{klass_name} to #{target_klass}"
        end
      end
      
    end # klasses.each
  end

def check_mode_klass_exists(klasses, t_klass, klass_name) 
    target_klass = nil
        if klasses.keys.include? t_klass.singularize
          target_klass = t_klass.singularize
        elsif klasses.keys.include? t_klass.pluralize
          target_klass = t_klass.pluralize
        else
          raise "Class \"#{t_klass}\" related with \"#{klass_name}\", don't exists. Please check if is misspelled" unless klasses[target_klass]
        end
   return target_klass
end

#dtd_to_mscff_yaml("test/dtd_for_nlp.dtd")