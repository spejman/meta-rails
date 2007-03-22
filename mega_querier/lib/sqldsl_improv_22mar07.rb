# require "sqldsl"
# require  Dir["tmp/sqldsl/*"][0]

class ReceiveAny < BlankSlate
  
  def like(arg)
    builder.like self, arg
  end
  alias =~ like

end
class WhereBuilder
  def like(lval, rval)
    add_condition(lval, "LIKE", rval)
  end
end

class AndWhereBuilder < WhereBuilder
  
  # call-seq: and_where.to_sql -> a_string
  # 
  # Returns a string by collecting all the conditions and joins them with ' and '.
  # 
  #    AndWhereBuilder.new [] do 
  #      equal :column1, 10
  #      equal :column2, 'book'
  #    end.to_sql         #=> " and (column1 = 10 and column2 = 'book')"
  def to_sql
    " and (#{sql_parts.join(' AND ')})"
  end
end

class SqlStatement
  # call-seq: sql_statement.or { block } -> a_sql_statement
  # 
  # Creates a new OrWhereBuilder instance, passing the block as a parameter, then executes to_sql on the OrWhereBuilder instance.
  # The resulting string from the OrWhereBuilder instance is appended to the SQL statement.
  # Returns self.
  # 
  #    Select[1].where { equal :column1, 1 }.or { equal :column1, 100 }.to_sql       #=> "select 1 where column1 = 1 or column1 = 100"
  def and(&block)
    @to_sql += AndWhereBuilder.new(self.tables, &block).to_sql
    self
  end

end

class InnerJoinBuilder 
  def [](*table_names)
    @select_builder.inner_join_table(table_names) 
  end
end

class Select < SqlStatement
  def inner_join_table(*table_names)
    @to_sql << " inner join "
    table_names.flatten!
    @to_sql += table_names.inject([]) do |result, element|
      if element.to_s =~ / as /
        @tables << element.to_s.split(/ as /).last.to_sym
        result << element.to_s.gsub(/ as /, " ").to_sym
      else
        @tables << element
        result << element
      end
    end.to_sql
    self
  end
end