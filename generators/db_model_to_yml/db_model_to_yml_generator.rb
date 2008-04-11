require 'active_support'
require 'yaml'
require File.join(File.dirname(__FILE__), "/../../lib/dtd_to_mscff_yaml.rb")
require 'check_consistency.rb'
require "infer_db_model"
include MetaRails::InferDbModel


class DbModelToYmlGenerator < Rails::Generator::Base
  attr_accessor :file_name, :scaffold_method
  
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

      klasses = klass_struct
      # Adding needed relations for building migrations and models
      #classes = add_relations_to_klasses(classes)
      
      m.directory  File.join('db')
      m.template 'actual_db_model.yml', File.join('db', "actual_db_model.yml"),
          :assigns => { :klasses => klasses }

    end
  end
    
end
