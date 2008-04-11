require 'active_support'
require "fileutils"
require 'dtd_to_mscff_yaml.rb'
require 'check_consistency.rb'

RAILS_RESERVED_ATTR = %w{ created_on updated_on}

META_WEB_SERVICES_GENERATOR_HOOK_FILE = File.join File.dirname(__FILE__), (("../"*5) + "lib/meta_web_services_generator_hook.rb")
require META_WEB_SERVICES_GENERATOR_HOOK_FILE if File.exists? META_WEB_SERVICES_GENERATOR_HOOK_FILE


class MetaWebServicesGenerator < Rails::Generator::Base
  attr_accessor :file_name
  
  def initialize(*runtime_args)
     super(*runtime_args)
     @file_name = args[0]
     raise "Filename of database schema file not given." unless @file_name
  end

  def manifest
    record do |m|
      #
      # { class_name_1 => {"class_attr"=>{"attr_name_1"=>"attr_type_1", ...},
      #                   "class_ass" => [ {"ass_type_1" => "relation_1"}, {..}, ... ] }
      # 
      # Ej: { "lexical_entry" => { "class_attr" => {"created_on"=>"date", "name"=>"string"}, 
      #           "class_ass" => [ {"has_many"=>"senses"}, {"has_many"=>"syntactic_behaviours"},
      #                            {"belongs_to"=>"lexicon"}]
      #                          },
      #       ... }
      #
      classes = YAML.load(File.open(@file_name)) if @file_name[-4..-1] == ".yml"
      classes = dtd_to_mscff_yaml(@file_name) if @file_name[-4..-1] == ".dtd"
      # Adding needed relations between models
      classes = add_relations_to_klasses(classes)
      
      raise "Consistency error." unless check_consitency(classes)

      # Adding needed relations for building migrations and models
      classes = add_relations_to_klasses(classes)
      
      # Here the meta_web_services generator tries to execute the hook if is defined
      # to execute it you must define a method called meta_web_services_generator_classes_hook(classes).
      # You can use the atomatically loaded file RAILS_ROOT/lib/meta_web_services_generator_hook.rb to
      # define it.
      classes = meta_web_services_generator_classes_hook(classes) if defined?(meta_web_services_generator_classes_hook) == "method"
      if defined?(meta_web_services_generator_extra_methods_hook!) == "method"
        # Returns extra methods and can also modify classes method
        extra_methods, classes = meta_web_services_generator_extra_methods_hook!(classes)
      else
        extra_methods = {:api => {}, :controller => {}} # No extra methods
      end
      
      m.directory  File.join('app/apis')
      m.directory  File.join('app/apis/meta_web_services_ws')      
      m.directory  File.join('app/controllers/meta_web_services_ws')      

      classes.each_with_index do |class_def, index|        
        # add foreign keys
        fks = []
        class_def[1]["class_ass"].select { |ass| (ass.has_key? "belongs_to" or ass.has_key? "has_one") }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          fks << fk_class_name
        end
        fks.uniq!

        habtm = []
        class_def[1]["class_ass"].select { |ass| ass.has_key? "has_and_belongs_to_many" or ass.has_key? "has_many" }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          habtm << fk_class_name #if class_def[0] < fk_class_name          
        end
        habtm.uniq!
        
        if class_def[1]["class_attr"]
          attr_list = (class_def[1]["class_attr"].keys - RAILS_RESERVED_ATTR).sort.join(", ")
        else
          attr_list = ""
        end
        # User for calling ActiveRecordObject.create and ActiveRecordObject.update
        attr_hash = attr_list.split(", ").collect {|a| ":#{a} => #{a}" }.join(", ")
        attr_hash += ((attr_hash.blank?) ? "" : ", " ) + fks.collect {|fk| ":#{fk} => #{fk}" }.join(", ") unless fks.empty?
        
        attr_list += ((attr_list.blank?) ? "" : ", " ) + fks.collect {|fk| fk+"_id" }.join(", ") unless fks.empty?
        # Used for generate the api definition
        attr_hash_with_type = attr_list.split(", ").collect do |a|
            "{ :#{a} => :" + ((class_def[1]["class_attr"][a].to_s if class_def[1]["class_attr"] and class_def[1]["class_attr"][a]) || "int") + " }"
        end.join(", ")
        m.template 'webservice_controller.rb', File.join('app/controllers/meta_web_services_ws', "ws_#{class_def[0].tableize}_controller.rb"),
          :assigns => { :ws_name => "ws_" + class_def[0].tableize,
                        :klass_attr => class_def[1]["class_attr"],
                        :fks => fks,
                        :attr_list => attr_list,
                        :attr_hash => attr_hash,
                        :habtm => habtm,
                        :klass => class_def[0].underscore.classify,
                        :extra_methods => extra_methods[:controller][class_def[0]] }
        m.template 'api.rb', File.join('app/apis/meta_web_services_ws', "ws_#{class_def[0].tableize}_api.rb"),
          :assigns => { :ws_name => "ws_" + class_def[0].tableize,
                        :klass_attr => class_def[1]["class_attr"],
                        :fks => fks,
                        :attr_list => attr_list,
                        :attr_hash => attr_hash,
                        :attr_hash_with_type => attr_hash_with_type,
                        :habtm => habtm,
                        :klass => class_def[0].underscore.classify,
                        :extra_methods => extra_methods[:api][class_def[0]] }

      end
      end    
  end
  
  def generate(args)
    Rails::Generator::Scripts::Generate.new.run(args)
  end
  
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
    
end
