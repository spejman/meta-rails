require 'active_support'
puts "aqui"
puts RAILS_ROOT
Dir["../../*"].each { |l| puts l }
if require 'dtd_to_mscff_yaml.rb'
puts "va" 
else
puts "noooo va"
end

class MetaScaffoldGenerator < Rails::Generator::Base
  attr_accessor :file_name, :scaffold_method
  
  def initialize(*runtime_args)
     super(*runtime_args)
     @file_name = args[0]
     @scaffold_method = args[1]
     @scaffold_method = "scaffold" unless @scaffold_method
     puts "file: #{@file_name}"
    #  classes = dtd_to_yaml(@file_name)

     # puts "error" unless check_consitency(classes)

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
      
      exit unless check_consitency(classes)
      
      m.directory  File.join('db/migrate')
      classes.each_with_index do |class_def, index|        
        # add foreign keys
        fks = []
        class_def[1]["class_ass"].select { |ass| (ass.has_key? "belongs_to" or ass.has_key? "has_one") }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize.singularize
          fks << "#{fk_class_name}_id"
        end

        habtm = []
        class_def[1]["class_ass"].select { |ass| ass.has_key? "has_and_belongs_to_many" }.each do |v_cont|
          fk_class_name = v_cont.values[0].tableize
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
#      m.class_collisions class_path, class_name, "#{class_name}WorkerTest"


      # Worker and test directories.
#      m.directory File.join('lib/workers', class_path)
      #m.directory File.join('test/unit', class_path)
      m.puts "Begin migration ******"
      m.system("rake db:migrate") #TODO: Use rake directly not using system call.
      m.puts "End migration ******"

      if @scaffold_method
        class_names = classes.collect {|class_name, class_def| class_name }
  
        if @scaffold_method == "active_scaffold"
          class_names.each do |class_name|
            m.template 'active_scaffold_controller.rb', File.join('app/controllers', "#{class_name.tableize}_controller.rb"),
            :assigns => { :class_name => class_name }                      
          end
          #TODO: copy layout_application_for_active_scaffold.rhtml to /app/views/layouts/application.rhtml
        else
          class_names.each {|class_name| m.generate([@scaffold_method, class_name]) }
          #m.generate([@scaffold_method, class_names].compact.flatten)
        end
        m.generate(["controller", "main", "index"])      
        m.template 'index.rhtml', File.join('app/views/main/index.rhtml'),
                      :assigns => { :class_names => class_names }
      end
      # Worker class and unit tests.
 #     m.template 'worker.rb',      File.join('lib/workers', class_path, "#{file_name}_worker.rb")
      #m.template 'unit_test.rb',  File.join('test/unit', class_path, "#{file_name}_worker_test.rb")
      #
      #
      # lexical_database lexical_entry lexicon sense syntactic_behaviour
    end
  end
  
  def generate(args)
    Rails::Generator::Scripts::Generate.new.run(args)
  end
  
  def check_consitency(klasses)
    puts "*** Data consitency not checked"
    
    klasses_eq_reserved_words = []    
    klasses.keys.each do |klass_name|
      klasses_eq_reserved_words << klass_name if Module.constants.include? klass_name.camelize \
          or Module.constants.include? klass_name.singularize.camelize
    end

    raise "Models with names equals to reserved words: " + klasses_eq_reserved_words.join(", ") \
      unless klasses_eq_reserved_words.empty?

    return true
  end
  
end
