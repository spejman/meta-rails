class SqlStatement
  attr_accessor :tables
  attr_reader :to_sql

  def initialize(sql)  #:nodoc:
    @to_sql = sql
  end
  
  # call-seq: sql_statement.where { block } -> a_sql_statement
  # 
  # Creates a new WhereBuilder instance, passing the block as a parameter, then executes to_sql on the WhereBuilder instance.
  # The resulting string from the WhereBuilder instance is appended to the SQL statement.
  # Returns self.
  # 
  #    Select[1].where { equal :column1, 1 }.to_sql       #=> "select 1 where column1 = 1"
  def where(&block)
    @to_sql += WhereBuilder.new(self.tables, &block).to_sql
    self
  end
  
  # call-seq: sql_statement.or { block } -> a_sql_statement
  # 
  # Creates a new OrWhereBuilder instance, passing the block as a parameter, then executes to_sql on the OrWhereBuilder instance.
  # The resulting string from the OrWhereBuilder instance is appended to the SQL statement.
  # Returns self.
  # 
  #    Select[1].where { equal :column1, 1 }.or { equal :column1, 100 }.to_sql       #=> "select 1 where column1 = 1 or (column1 = 100)"
  def or(&block)
    @to_sql += OrWhereBuilder.new(self.tables, &block).to_sql
    self
  end
  
  # call-seq: sql_statement.and { block } -> a_sql_statement
  # 
  # Creates a new AndWhereBuilder instance, passing the block as a parameter, then executes to_sql on the AndWhereBuilder instance.
  # The resulting string from the AndWhereBuilder instance is appended to the SQL statement.
  # Returns self.
  # 
  #    Select[1].where { equal :column1, 1 }.and { equal :column2, 100 }.to_sql       #=> "select 1 where column1 = 1 and (column2 = 100)"
  def and(&block)
    @to_sql += AndWhereBuilder.new(self.tables, &block).to_sql
    self
  end
  
end