class JoinBuilder #:nodoc:
  def initialize(select_builder, join_type)
    @select_builder = select_builder
    @join_type = join_type
  end
  
  def [](*table_names)    
    @select_builder.join_table(@join_type, table_names)
  end
end