class InnerJoinBuilder #:nodoc:
  def initialize(select_builder)
    @select_builder = select_builder
  end
  
  def [](*table_names)
    @select_builder.inner_join_table(table_names)
  end
end