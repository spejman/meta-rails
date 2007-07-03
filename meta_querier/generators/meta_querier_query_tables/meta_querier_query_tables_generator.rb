class MetaQuerierQueryTablesGenerator < Rails::Generator::NamedBase

  def initialize(runtime_args, runtime_options = {})
          # Make the generator work without extra options, only with:
          # script/generate meta_querier_query_tables
         runtime_args << 'add_meta_querier_query_tables' if runtime_args.empty?
         super
  end
  
  def manifest
    record do |m|
      m.directory File.join('db/migrate', class_path)
      m.migration_template 'add_meta_querier_query_tables.rb', 'db/migrate'
    end
  end

end
