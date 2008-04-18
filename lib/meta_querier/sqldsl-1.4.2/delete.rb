class Delete < SqlStatement
  class << self
    # call-seq: Delete.from -> a_delete
    # 
    # Returns a Delete instance with the SQL initialized to 'delete from '
    # 
    #    Delete.from.to_sql       #=> "delete from "
    def from      
      self.new('delete from ')
    end
  end
  
  # call-seq: delete[table] -> a_delete
  # 
  # Returns a Delete instance with the table appended to the SQL statement.
  # 
  #    Delete.from[:table1].to_sql       #=> "delete from table1"
  def [](table)
    @to_sql += table.to_sql
    @tables = [table]
    self
  end
end