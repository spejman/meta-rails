require 'active_support'


# Autocompletes missing relations two ways relations.
# When can have this kind of relations:
#   - has_and_belongs_to_many <--> has_and_belongs_to_many (n <--> n)
#   - has_many <--> belongs_to (n <--> 1)
#   - has_one <--> belongs_to (1 <--> 1)
#
def add_relations_to_klasses(klasses)    
    
    klasses.each do |klass_name, klass_info|
      puts "* " + klass_name
      
      # Autocomplete or correct classes related with has_many (has_many <--> *)
      klass_info["class_ass"].select{|r| r["has_many"]}.map{|r| r.values}.flatten.each do |t_klass|
        puts "--> " + t_klass
        puts ""
        target_klass = check_mode_klass_exists(klasses, t_klass, klass_name)

        # Check if habtm.
        # If we found has_many <--> has_many, this must be changed 
        # to has_and_belongs_to_many <--> has_and_belongs_to_many
        if klasses[target_klass]["class_ass"].select{|r| r["has_many"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"].delete( {"has_many" => klass_name})
            klasses[klass_name]["class_ass"].delete( {"has_many" => target_klass})
            klasses[target_klass]["class_ass"] << {"has_and_belongs_to_many" => klass_name}
            klasses[klass_name]["class_ass"] << {"has_and_belongs_to_many" => target_klass}
        # Check if target class must have to be belongs_to.
        # If not has_many <--> has_many (converted to has_and_belongs_to_many <--> has_and_belongs_to_many),
        # then must be has_many <--> belongs_to
        elsif !klasses[target_klass]["class_ass"].select{|r| r["belongs_to"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"] << { "belongs_to" => klass_name }
            puts "Added #{klass_name} to #{target_klass}"
        end
      end
      
      # Autocomplete or correct classes related with has_many (has_one <--> *)
      # Checks for the classes that have relations with "has_one" and if exist someone
      # without the related class associated with "belongs_to", it adds the relation.
      klass_info["class_ass"].select{|r| r["has_one"]}.map{|r| r.values}.flatten.each do |t_klass|
        target_klass = check_mode_klass_exists(klasses, t_klass, klass_name)
        
        if !klasses[target_klass]["class_ass"].select{|r| r["belongs_to"]}.map{|r| r.values}.flatten.include? klass_name
            klasses[target_klass]["class_ass"] << { "belongs_to" => klass_name }
            puts "Added #{klass_name} to #{target_klass}"
        end
      end
      
    end # klasses.each
  end

# Checks if a klass exist with different cardinality name and returns this name.
# If don't exist any posible convination of this name, raises a Exception
# TODO: This can let to incongruences in the models. Make sure it's necessary
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

  
  # Checks for the klasses struct cosistency. Evaluates if:
  #  - There is no reserved words colision.
  #  - RoR infletions are correct (a.singular = a.singular.singular and so on).
  def check_consitency(klasses)
    return false if klasses.nil? or klasses.empty?
    
    # Check for reserved words colisions
    klasses_eq_reserved_words = check_for_reserved_words(klasses.keys)

    raise "Models with names equals to reserved words: " + klasses_eq_reserved_words.join(", ") \
    unless klasses_eq_reserved_words.empty?
    
    # Check for errors in Ruby on Rails inflection
    klasses_with_diff_sig_to_pl = check_for_incorrect_inflection(klasses.keys)
    raise "Models with incorrect Ruby on Rails inflection: " + klasses_with_diff_sig_to_pl.join(", ") \
    unless klasses_with_diff_sig_to_pl.empty?

    return true
  end


def check_for_reserved_words(klass_list)

    klasses_eq_reserved_words = []    
    klass_list.each do |klass_name|
      klasses_eq_reserved_words << klass_name if Module.constants.include? klass_name.camelize \
          or Module.constants.include? klass_name.singularize.camelize
    end
    
    return klasses_eq_reserved_words
end

def check_for_incorrect_inflection(klass_list)

    klasses_with_diff_sig_to_pl = []
    klass_list.each do |klass_name|
      klasses_with_diff_sig_to_pl << klass_name if \
          klass_name.pluralize.singularize.pluralize != klass_name.singularize.pluralize \
          || klass_name.pluralize.singularize != klass_name.singularize
    end
    
    return klasses_with_diff_sig_to_pl
end
