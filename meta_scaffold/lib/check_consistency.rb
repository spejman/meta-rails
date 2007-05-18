require 'active_support'

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
