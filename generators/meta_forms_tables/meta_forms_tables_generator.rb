# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Generator that will create MetaQuerier tables (calling AddMetaQuerierQueryTables migration).

class MetaFormsTablesGenerator < Rails::Generator::NamedBase

  def initialize(runtime_args, runtime_options = {})
          # Make the generator work without extra options, only with:
          # script/generate meta_querier_query_tables
         runtime_args << 'add_meta_forms_tables' if runtime_args.empty?
         super
  end
  
  def manifest
    record do |m|
      m.directory File.join('db/migrate', class_path)
      m.migration_template 'add_meta_forms_tables.rb', 'db/migrate'
    end
  end

end
