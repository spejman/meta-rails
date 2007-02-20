#require "rubygems"
#require "active_support"

RESERVED_MIGRATION_WORDS = ["id"]

def dtd_to_mscff_yaml(filename)
  file_content = File.open(filename, "r").readlines.join
  
  elements = file_content.scan(/<!ELEMENT (\/?[^\>]+)\>/)
  elements = elements.flatten.each {|v| v.gsub!("\n", " "); v.gsub!(/\(|\)|,/, "")}

  h_yaml = {}
  elements.each do |element|
    element = element.split
    h_yaml[element[0]] = {}
    h_yaml[element[0]]["class_ass"] = element[1..-1].collect do |relation|
      case relation[-1].chr
        when "*"
          {"has_many" => relation[0..-2]}
        when "+"
          {"has_many" => relation[0..-2]}
        when "?"
          {"has_one" => relation[0..-2]}
        else
          {"has_one" => relation[0..-2]}
#          raise "Unable to determine arity of [#{element[0]}] --> [#{relation}]"
        end
    end
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
            h_yaml[attribute[0]]["class_attr"][att_definition[0]] = :string
          end
      end
    end
  end

  return h_yaml
end

#dtd_to_mscff_yaml("test/dtd_for_nlp.dtd")