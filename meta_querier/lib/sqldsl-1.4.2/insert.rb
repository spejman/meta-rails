class Insert < SqlStatement
  class << self
    # call-seq: Insert.into -> Insert
    # 
    # Returns the Insert class.  Unnecessary and only available to mimic SQL statements.
    # 
    #    Insert.into       #=> Insert
    def into
      self
    end
    
    # call-seq: Insert[table] -> an_insert
    # 
    # Returns an Insert instance with the SQL initialized to 'insert into [table] '
    # 
    #    Insert[:table1].to_sql       #=> "insert into table1 "
    def [](table)
      self.new("insert into #{table.to_sql}")
    end
  end
  
  # call-seq: insert[column1,...] -> an_insert
  # 
  # Returns an Insert instance with the columns appended to the SQL statement.
  # 
  #    Insert.into[:table1][:column1, :column2].to_sql       #=> "insert into table1 (column1, column2)"
  def [](*columns)
    @to_sql += " (#{columns.join(', ')})"
    self
  end
  
  # call-seq: insert.values { block } -> an_insert
  #           insert.values(arg,...)
  # 
  # If a block is given:
  # Ignores any parameters given to the method.
  # Executes the block then calls +to_sql+ on the result.
  # Returns an Insert instance with the result of the block's execution appended to the SQL statement.
  # 
  #    insert = Insert.into[:table1][:column1].values { Select['book'] }       
  #    insert.to_sql      #=> "insert into table1 (column1) select 'book'"
  #
  # If no block is given:
  # Returns an Insert instance with the args appended to the SQL statement as values
  # 
  #    insert = Insert.into[:table1][:column1, :column2].values(10, 'book')
  #    insert.to_sql      #=> "insert into table1 (column1, column2) values (10, 'book')"
  def values(*args)
    @to_sql += case
      when block_given? then " #{yield.to_sql}"
      else " values (#{args.to_sql})"
    end
    self
  end
end