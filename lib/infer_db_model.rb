# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

module MetaRails
  
  module InferDbModel

      # Returns the klass_struct structure with all the schema data of the db.
      #    { class_name_1 => { "class_attr" => { attr_name_1 => attr_type_1, ..., attr_name_n => attr_type_n },
      #                        "class_ass" => [ {rel_type_a => rel_target_1}, {rel_type_a => rel_target_2},
      #                                          ..., {rel_type_b => rel_target_n} ] },
      #       ...,
      #       class_name_n => { "class_attr" => { attr_name_1 => attr_type_1, ..., attr_name_n => attr_type_n },
      #                        "class_ass" => [ {rel_type_a => rel_target_1}, {rel_type_a => rel_target_2},
      #                                          ..., {rel_type_b => rel_target_n} ] },
      #     }
      #
      # Example:
      #     { "Artist" => { "class_attr" => { "name" => :string, "born_date" => :date },
      #                      "class_ass" => { "has_many" => "published_albums" },
      #       "PublishedAlbums" => { "class_attr" => { "title" => :string, "date" => :date },
      #                      "class_ass" => { "belongs_to" => "artist" }
      #     }
      
      def klass_struct(excluded_tables = [], excluded_columns = [])
        begin
          if defined? Memcached
            cache = Memcached.new(MEMCACHED_SERVER)
            return cache.get("klass_struct")
          end
        rescue
          logger.info "Memcached access to klass_struct failed."
        end
        
        ar_db_no_relevant_columns = ["id"] + []
        
        # Don't include internal rails tables
        ar_db_reserved_words = ["schema_info", "engine_schema_info"]
        # Don't include desired excluded tables
        ar_db_reserved_words += excluded_tables
        # Don't include sitealizer plugin tables
        ar_db_reserved_words += ["sitealizer"] if File.exist?(File.join(RAILS_ROOT, "vendor/plugins/sitealizer"))
        # Don't include metaquerier query management tables
        ar_db_reserved_words += [MetaQuerierQuery.table_name, MetaQuerierQueryCondition.table_name]
        # Don't include metaquerier hook defined tables
        ar_db_reserved_words += META_QUERIER_HOOK_TABLES if defined? META_QUERIER_HOOK_TABLES
        
        klasses = {}
        
        # Get model names
        tables = get_table_names(ar_db_reserved_words)
        activerecord_classes = get_activerecord_classes(tables)
      
        # Get model attributes
        activerecord_columns = {}
        activerecord_classes.each {|ar_class_name| ar_db_no_relevant_columns << ar_class_name.underscore + "_id"}
        activerecord_classes.each {|ar_class_name| activerecord_columns[ar_class_name] = get_activerecord_attributes(ar_class_name, ar_db_no_relevant_columns)}
      
        # Get model associations
        activerecord_associations = {}
        activerecord_classes.each {|ar_class_name| activerecord_associations[ar_class_name] = get_activerecord_associations(ar_class_name)}
        activerecord_classes.each do |klass_name|
          klasses[klass_name] = { "class_attr" => activerecord_columns[klass_name] }
          klasses[klass_name]["class_ass"] = activerecord_associations[klass_name].collect {|rel_value, rel_type| {rel_type => rel_value.to_s}}
        end
        cache.set("klass_struct", klasses)
        return klasses
      end
      
      # Returns an array with all the table names (without the defined in ar_db_reserved_words) using
      # ActiveRecord methods.
      def get_table_names(ar_db_reserved_words) 
       table_names_hash = ActiveRecord::Base.connection.tables - ar_db_reserved_words
      end
      
      # Checks for each table name if it's defined an ActiveRecord model class related to it.
      # Returns an array with a class string for each valid table name (has an associated model).
      def get_activerecord_classes(table_names)
        activerecord_classes_names = []
        table_names.each do |table_name|
          table_name = table_name.classify
          begin # if table_name couldn't be a constant .constantize will throw a exception.
            activerecord_classes_names << table_name if table_name.constantize
          rescue; end
        end
        activerecord_classes_names
      end
      
      # For given class name checks for its columns (without ar_db_no_relevant_columns)
      # Returns a hash with keys equal to a column name an values equal to each column type.
      def get_activerecord_attributes(ar_class_name, ar_db_no_relevant_columns = [])
        columns = {}
        ActiveRecord::Base.connection.columns(ar_class_name.tableize).each {|c| 
            columns[c.name] = c.type unless ar_db_no_relevant_columns.include?(c.name)  }
        columns
      end
      
      # For given class name checks for its associated models (belongs_to, has_many, habtm, has_one)
      # Returns a hash with keys equal to the relation types that exist for the given class, and with
      # values equal to arrays of related classes with this related type for the given class.
      def get_activerecord_associations(ar_class_name)
        associations = {}
        ar_class_name.constantize.reflections.each do |a_name, a_values|
          associations[a_name] = a_values.macro.to_s
        end
        associations
      end
  end
    
  
end