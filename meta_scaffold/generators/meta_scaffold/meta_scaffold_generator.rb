require 'active_support'
require "fileutils"
require 'dtd_to_mscff_yaml.rb'

class MetaScaffoldGenerator < Rails::Generator::Base
  attr_accessor :file_name, :scaffold_method
  
  def initialize(*runtime_args)
     super(*runtime_args)
     @file_name = args[0]
     raise "Filename of database schema file not given." unless @file_name
     @scaffold_method = args[1]
     @scaffold_method = "active_scaffold" unless @scaffold_method
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
      
      m.directory  File.join('db/migrate')
      classes.each_with_index do |class_def, index|        
        # add foreign keys
        fks = []
        class_def[1]["class_ass"].select { |ass| (ass.has_key? "belongs_to" or ass.has_key? "has_one") }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          fks << fk_class_name
        end

        habtm = []
        class_def[1]["class_ass"].select { |ass| ass.has_key? "has_and_belongs_to_many" }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          habtm << fk_class_name if class_def[0] < fk_class_name          
        end

      
        m.template 'migration.rb', File.join('db/migrate', "00#{index+1}_create_#{class_def[0].tableize}.rb"),
          :assigns => { :class_name => class_def[0].tableize,
                        :class_attr => class_def[1]["class_attr"] || [],
                        :fks => fks, :habtm => habtm }
        m.template 'model.rb', File.join('app/models', "#{class_def[0].tableize.singularize}.rb"),
          :assigns => { :class_name => class_def[0].tableize,
                        :class_ass => class_def[1]["class_ass"]}

      end

      # Check for class naming collisions.
      #m.class_collisions class_path, class_name, "#{class_name}WorkerTest"


      m.puts "Begin migration ******"

      if RUBY_PLATFORM =~ /mswin32/
        # In windows system method with rake don't work unless you redirect the
        # output.
        m.system("rake db:migrate > meta_scaffold-win.log")
      else
        m.system("rake db:migrate") #TODO: Use rake directly not using system call.
      end
      m.puts "End migration ******"

      if @scaffold_method
        #m.directory  File.join('public/stylesheets/meta_rails')
        #m.file File.join('../files/', 'meta_scaffold.css'), File.join('public/stylesheets/meta_rails','meta_scaffold.css')
        class_names = classes.collect {|class_name, class_def| class_name }
  
        if @scaffold_method == "active_scaffold"
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
        # Generate meta_scaffold_info, that is the index or menu of meta_scaffold.
        m.generate(["controller", "meta_scaffold_info", "index"])  
        m.template 'index.rhtml', File.join('app/views/meta_scaffold_info/index.rhtml'),
                      :assigns => { :class_names => class_names }, :collision => :force
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
