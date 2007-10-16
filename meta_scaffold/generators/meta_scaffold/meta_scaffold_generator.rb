require 'active_support'
require "fileutils"
require File.join(File.dirname(__FILE__), "/../../lib/dtd_to_mscff_yaml.rb")
require 'check_consistency.rb'
require "infer_db_model"
include MetaRails::InferDbModel


class MetaScaffoldGenerator < Rails::Generator::Base
  attr_accessor :file_name, :scaffold_method
  
  def initialize(*runtime_args)
    super(*runtime_args)

    @file_name = args[0]
    raise "Filename of database schema file not given." unless @file_name
     
    # The only scaffold method supported is active_scaffold.
    # @scaffold_method = args[1]
    @scaffold_method = "active_scaffold" #unless @scaffold_method
     
    @hasto_create_migrations = true
    @hasto_create_models = true
    @hasto_create_from_db = false
    @incremental = false
     
    args[1..-1].each do |arg|
      case arg
      when "nomigrations"
        @hasto_create_migrations = false
      when "nomodels"
        @hasto_create_models = false
        @hasto_create_migrations = false
      when "nocontrollers"
        @scaffold_method = nil
      when "fromdb"
        @hasto_create_from_db = true
        #          hasto_create_models = false
        @hasto_create_migrations = false
        @incremental = false
      when "incremental"
        @incremental = true
        @hasto_create_from_db = false
      else
        raise "Wrong parameter: #{arg}"
      end
    end
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
      if @hasto_create_from_db
        classes = klass_struct
      elsif @incremental
        db_klasses = klass_struct
        new_klasses = YAML.load(File.open(@file_name)) if @file_name[-4..-1] == ".yml"
        new_kclasses = dtd_to_mscff_yaml(@file_name) if @file_name[-4..-1] == ".dtd"          
        classes = changes_to_apply(db_klasses, new_klasses)
      else
        classes = YAML.load(File.open(@file_name)) if @file_name[-4..-1] == ".yml"
        classes = dtd_to_mscff_yaml(@file_name) if @file_name[-4..-1] == ".dtd"
        # If classes loaded from a file, check its consistency
        raise "Consistency error." unless check_consitency(classes)
      end
      
      # Adding needed relations for building migrations and models
      classes = add_relations_to_klasses(classes)
      
      m.directory  File.join('db/migrate')
      classes.each_with_index do |class_def, index|        
        # Add foreign keys:
        
        # The class that has belongs_to must create attribute "#{target_model}_id" for 
        # the relations has_many <--> belongs_to or has_one <--> belongs_to.
        # 
        # Now store this relations into fks variable and later pass as a parameter to
        # the migration.rb template
        fks = []
        class_def[1]["class_ass"].select { |ass| (ass.has_key? "belongs_to") }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          fks << fk_class_name
        end

        habtm = []
        # In has_and_belongs_to_many relations a auxiliar table must be used to connect
        # the two models the name of this table must be a composition of the two classes
        # names. The class that is first in alphabetical order must be the first in the composition
        # and the other the second. Example: songs <-- has_and_belongs_to_many --> instruments, its
        # auxiliar table must be instruments_songs
        # 
        # Now store this relations in habtm variable to later pass as a parameter to the migration.rb
        # template only once (when we found the first model in alphabetical order).
        class_def[1]["class_ass"].select { |ass| ass.has_key? "has_and_belongs_to_many" }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          habtm << fk_class_name if class_def[0] < fk_class_name          
        end

        # Generate the migration
        m.template 'migration.rb', File.join('db/migrate', "#{next_migration_string(index+1)}_create_#{class_def[0].tableize}.rb"),
          :assigns => { :class_name => class_def[0].tableize,
          :class_attr => class_def[1]["class_attr"] || [],
          :add => class_def[1]["add"] || [],
          :remove => class_def[1]["remove"] || [],
          :modify => class_def[1]["modify"] || [],
          :fks => fks, :habtm => habtm } if @hasto_create_migrations
        
        # Generate the model
        m.template 'model.rb', File.join('app/models', "#{class_def[0].tableize.singularize}.rb"),
          :assigns => { :class_name => class_def[0].tableize,
          :class_ass => class_def[1]["class_ass"]} if @hasto_create_models

      end

      # Run the migrations
      if @hasto_create_migrations
        m.puts "Begin migration ******"
        if RUBY_PLATFORM =~ /mswin32/
          # In windows system method with rake don't work unless you redirect the
          # output.
          m.system("rake db:migrate > meta_scaffold-win.log")
        else
          m.system("rake db:migrate") #TODO: Use rake directly not using system call.
        end
        m.puts "End migration ******"
      end
      
      # Run the scaffold and copy necessary files
      if @scaffold_method

        class_names = classes.collect {|class_name, class_def| class_name }
  
        if @scaffold_method == "active_scaffold"
          # MetaScaffoldModels controllers super class
          m.file File.join('../files/', 'meta_scaffold_base_controller.rb'), File.join('app/controllers','meta_scaffold_base_controller.rb')

          m.directory File.join('app/controllers/meta_scaffold_models')
          class_names.each do |class_name|
            m.template 'active_scaffold_controller.rb', File.join('app/controllers/meta_scaffold_models', "#{class_name.tableize}_controller.rb"),
              :assigns => { :class_name => class_name.tableize }                      
          end
          m.template 'layout_for_meta_scaffold.rhtml', File.join('app/views/layouts', "meta_scaffold.rhtml"),
            :assigns => { :class_names => class_names, :is_active_scaffold => true }
          m.template 'layout_for_meta_scaffold.rhtml', File.join('app/views/layouts', "meta_scaffold_info.rhtml"),
            :assigns => { :class_names => class_names, :is_active_scaffold => false }
        else
          class_names.each {|class_name| m.generate([@scaffold_method, class_name]) }
          m.template 'layout_for_meta_scaffold.rhtml', File.join('app/views/layouts', "application.rhtml"),
            :assigns => { :class_names => class_names, :is_active_scaffold => false }

          #m.generate([@scaffold_method, class_names].compact.flatten)
        end

        # Meta scaffold models controllers test
        m.file File.join('../files/', 'meta_scaffold_models_test.rb'), File.join('test/integration','meta_scaffold_models_test.rb')
        
        # Generate meta_scaffold_info, that is the index or menu of meta_scaffold.
        # Controller, view and test
        m.file File.join('../files/', 'meta_scaffold_info_controller.rb'), File.join('app/controllers','meta_scaffold_info_controller.rb')
        m.directory  File.join('app/views/meta_scaffold_info')
        m.template 'index.rhtml', File.join('app/views/meta_scaffold_info/index.rhtml'),
          :assigns => { :class_names => class_names }, :collision => :force        
        m.file File.join('../files/', 'meta_scaffold_info_controller_test.rb'), File.join('test/functional','meta_scaffold_info_controller_test.rb')
        
        # Singleton used for comunicate controllers with models.
        m.file File.join('../files/', 'metarails_singleton.rb'), File.join('app/models','metarails_singleton.rb')
      
      end

    end
  end

  # Returns the current migration number of the application (as a integer).
  def current_migration_number
    Dir.glob("db/migrate/[0-9]*.rb").inject(0) do |max, file_path|
      n = File.basename(file_path).split('_', 2).first.to_i
      if n > max then n else max end
    end
  end

  # Get the filename of the next migration
  def next_migration_string(index, padding = 3)
    "%.#{padding}d" % (current_migration_number + index)
  end
  
  
  def generate(args)
    Rails::Generator::Scripts::Generate.new.run(args)
  end
  
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
    
end
