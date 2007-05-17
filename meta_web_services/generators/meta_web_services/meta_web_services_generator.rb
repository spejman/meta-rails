require 'active_support'
require "fileutils"
require 'dtd_to_mscff_yaml.rb'

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
      
      raise "Consistency error." unless check_consitency(classes)

      # Adding needed relations for building migrations and models
      classes = add_relations_to_klasses(classes)
      
      m.directory  File.join('app/apis')
      classes.each_with_index do |class_def, index|        
        # add foreign keys
        fks = []
        class_def[1]["class_ass"].select { |ass| (ass.has_key? "belongs_to" or ass.has_key? "has_one") }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          fks << fk_class_name
        end

        habtm = []
        class_def[1]["class_ass"].select { |ass| ass.has_key? "has_and_belongs_to_many" or ass.has_key? "has_many" }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          habtm << fk_class_name #if class_def[0] < fk_class_name          
        end

        attr_list = class_def[1]["class_attr"].keys.sort.join(", ")
        attr_list += ", " + fks.collect {|fk| fk+"_id" }.join(", ") unless fks.empty?
        attr_hash = attr_list.split(", ").collect {|a| ":#{a} => #{a}" }.join(", ")
        attr_hash_with_type = attr_list.split(", ").collect do |a|
            "{ :#{a} => :" + (class_def[1]["class_attr"][a] || "int") + " }"
        end.join(", ")
        m.template 'webservice_controller.rb', File.join('app/controllers', "ws_#{class_def[0].tableize}_controller.rb"),
          :assigns => { :ws_name => "ws_" + class_def[0].tableize,
                        :klass_attr => class_def[1]["class_attr"],
                        :fks => fks,
                        :attr_list => attr_list,
                        :attr_hash => attr_hash,
                        :habtm => habtm,
                        :klass => class_def[0].classify }
        m.template 'api.rb', File.join('app/apis', "ws_#{class_def[0].tableize}_api.rb"),
          :assigns => { :ws_name => "ws_" + class_def[0].tableize,
                        :klass_attr => class_def[1]["class_attr"],
                        :fks => fks,
                        :attr_list => attr_list,
                        :attr_hash => attr_hash,
                        :attr_hash_with_type => attr_hash_with_type,
                        :habtm => habtm,
                        :klass => class_def[0].classify }      

      end
      end    
  end
  
  def generate(args)
    Rails::Generator::Scripts::Generate.new.run(args)
  end
  
  def check_consitency(klasses)
    return false if klasses.nil? or klasses.empty?
    
    # Check for reserved words colisions
    klasses_eq_reserved_words = []    
    klasses.keys.each do |klass_name|
      klasses_eq_reserved_words << klass_name if Module.constants.include? klass_name.camelize \
          or Module.constants.include? klass_name.singularize.camelize
    end

    raise "Models with names equals to reserved words: " + klasses_eq_reserved_words.join(", ") \
      unless klasses_eq_reserved_words.empty?
    
    # Check for errors in Ruby on Rails inflection
    klasses_with_diff_sig_to_pl = []
    klasses.keys.each do |klass_name|
      klasses_with_diff_sig_to_pl << klass_name if \
          klass_name.pluralize.singularize.pluralize != klass_name.singularize.pluralize \
          || klass_name.pluralize.singularize != klass_name.singularize
    end

    raise "Models with incorrect Ruby on Rails inflection: " + klasses_with_diff_sig_to_pl.join(", ") \
      unless klasses_with_diff_sig_to_pl.empty?

    return true
  end
    
end
