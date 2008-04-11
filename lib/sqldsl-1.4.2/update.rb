class Update < SqlStatement
  class << self
    # call-seq: Update[table] -> an_update
    # 
    # Returns an Update instance with the SQL initialized to 'update [table] '
    # 
    #    Update[:table1].to_sql       #=> "update table1"
    def [](table)
      update = self.new("update #{table.to_sql}")
      update.tables = [table]
      update
    end
  end
  
  # call-seq: update.set -> update
  # 
  # Returns self.  Unnecessary and only available to mimic SQL statements.
  # 
  #    Update[:table1].set.to_sql       #=> "update table1"
  def set
    self
  end
  
  # call-seq: update[column1=>'book',...] -> an_update
  # 
  # Returns an Update instance with the set values appended to the SQL statement.
  # 
  #    update = Update[:table1].set[:column1=>'book', :column2=>10]
  #    update.to_sql       #=> "update table1 set column1 = 'book, column2 = 10"
  def [](hash)
    @to_sql += " set "
    set_args = []
    hash.each_pair do |col, val|
      set_args << "#{col.to_sql}=#{val.to_sql}"
    end
    @to_sql += set_args.sort.join(', ')
    self
  end
end