module MetaRails
  
  module InferDbModel
            
      def klass_struct
        ar_db_no_relevant_columns = ["id"]
        ar_db_reserved_words = ["schema_info", "engine_schema_info"]
        ar_db_reserved_words += ["sitealizer"] if File.exist?(File.join(RAILS_ROOT, "vendor/plugins/sitealizer"))
        
        klasses = {}
        tables = get_table_names(ar_db_reserved_words)
        activerecord_classes = get_activerecord_classes(tables)
      
        activerecord_columns = {}
        activerecord_classes.each {|ar_class_name| ar_db_no_relevant_columns << ar_class_name.underscore + "_id"}
        activerecord_classes.each {|ar_class_name| activerecord_columns[ar_class_name] = get_activerecord_attributes(ar_class_name, ar_db_no_relevant_columns)}
      
        activerecord_associations = {}
        activerecord_classes.each {|ar_class_name| activerecord_associations[ar_class_name] = get_activerecord_associations(ar_class_name)}
        activerecord_classes.each do |klass_name|
          klasses[klass_name] = { "class_attr" => activerecord_columns[klass_name] }
          klasses[klass_name]["class_ass"] = activerecord_associations[klass_name].collect {|rel_value, rel_type| {rel_type => rel_value.to_s}}
        end
        return klasses
      end
        
      def get_table_names(ar_db_reserved_words) 
       table_names_hash = ActiveRecord::Base.connection.tables - ar_db_reserved_words
      end
      
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
      
      
      def get_activerecord_attributes(ar_class_name, ar_db_no_relevant_columns)
        columns = {}
        ActiveRecord::Base.connection.columns(ar_class_name.tableize).each {|c| 
            columns[c.name] = c.type unless ar_db_no_relevant_columns.include?(c.name)  }
        columns
      end
      
      def get_activerecord_associations(ar_class_name)
        associations = {}
        ar_class_name.constantize.reflections.each do |a_name, a_values|
          associations[a_name] = a_values.macro.to_s
        end
        associations
      end
  end
    
  
end