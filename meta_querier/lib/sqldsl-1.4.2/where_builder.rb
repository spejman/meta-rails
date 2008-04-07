class WhereBuilder
  attr_reader :tables
  
  # call-seq: WhereBuilder.new(tables, &block) -> a_where_builder
  # 
  # Returns a new WhereBuilder.  At initialization time the block is instance evaled on the
  # new WhereBuilder instance.
  # 
  #    WhereBuilder.new [:table1] { equal :column1, 10 }.to_sql       #=> " where column1 = 10"
  def initialize(tables, &block)
    raise ArgumentError.new("no block given to where, check for parenthesis usage") unless block_given?
    @tables = tables.concat(eval("respond_to?(:tables) ? tables : []", block.binding))
    instance_eval(&block)
  end
  
  # call-seq: where.equal(arg1, arg2)
  # 
  # Appends an equality condition to the where SQL clause.
  # 
  #    where { equal :column1, 10 }.to_sql       #=> " where column1 = 10"
  def equal(lval, rval)
    add_condition(lval, "=", rval)
  end
  
  # call-seq: where.not_equal(arg1, arg2)
  # 
  # Appends a not equal condition to the where SQL clause.
  # 
  #    where { not_equal :column1, 10 }.to_sql       #=> " where column1 <> 10"
  def not_equal(lval, rval)
    add_condition(lval, "<>", rval)
  end
  
  # call-seq: where.less_than(arg1, arg2)
  # 
  # Appends a less than condition to the where SQL clause.
  # 
  #    where { less_than :column1, 10 }.to_sql       #=> " where column1 < 10"
  def less_than(lval, rval)
    add_condition(lval, "<", rval)
  end
  
  # call-seq: where.less_than_or_equal(arg1, arg2)
  # 
  # Appends a less than or equal condition to the where SQL clause.
  # 
  #    where { less_than_or_equal :column1, 10 }.to_sql       #=> " where column1 <= 10"
  def less_than_or_equal(lval, rval)
    add_condition(lval, "<=", rval)
  end
  
  # call-seq: where.greater_than(arg1, arg2)
  # 
  # Appends a greater than condition to the where SQL clause.
  # 
  #    where { greater_than :column1, 10 }.to_sql       #=> " where column1 > 10"
  def greater_than(lval, rval)
    add_condition(lval, ">", rval)
  end
  
  # call-seq: where.greater_than_or_equal(arg1, arg2)
  # 
  # Appends a greater than or equal condition to the where SQL clause.
  # 
  #    where { greater_than_or_equal :column1, 10 }.to_sql       #=> " where column1 >= 10"
  def greater_than_or_equal(lval, rval)
    add_condition(lval, ">=", rval)
  end
  
  # call-seq: where.is_in(arg1, arg2)
  # 
  # Appends an in condition to the where SQL clause.
  # 
  #    where { is_in :column1, [10, 20] }.to_sql       #=> " where column1 in (10, 20)"
  def is_in(lval, rval)
    add_parenthesis_condition(lval, "in", rval)
  end
  
  # call-seq: where.is_not_in(arg1, arg2)
  # 
  # Appends a not in condition to the where SQL clause.
  # 
  #    where { is_not_in :column1, [10, 20] }.to_sql       #=> " where column1 not in (10, 20)"
  def is_not_in(lval, rval)
    add_parenthesis_condition(lval, "not in", rval)
  end
  
  # call-seq: where.not_null(arg1)
  # 
  # Appends a not null condition to the where SQL clause.
  # 
  #    where { is_not_null :column1 }.to_sql       #=> " where column1 is not null"
  def is_not_null(column)
    sql_parts << "#{column.to_sql} is not null"
  end
  
  # call-seq: where.like(arg1, arg2)
  # 
  # Appends a like condition to the where SQL clause.
  # 
  #    where { like :column1, 'any' }.to_sql       #=> " where column1 like 'any'"
  def like(lval, rval)
    add_condition(lval, "like", rval)
  end
    
  # call-seq: where.exists(clause)
  # 
  # Appends an exists condition to the where SQL clause.
  # 
  #    where { exists 'select id from table1' }.to_sql       #=> " where exists (select id from table1)"
  def exists(clause)
    sql_parts << "exists (#{clause.to_sql})"
  end
  
  # call-seq: where.not_exists(clause)
  # 
  # Appends an exists condition to the where SQL clause.
  # 
  #    where { not_exists 'select id from table1' }.to_sql       #=> " where not exists (select id from table1)"
  def not_exists(clause)
    sql_parts << "not exists (#{clause.to_sql})"
  end
  
  # call-seq: where.to_sql -> a_string
  # 
  # Returns a string by collecting all the conditions and joins them with ' and '.
  # 
  #    WhereBuilder.new [] do 
  #      equal :column1, 10
  #      equal :column2, 'book'
  #    end.to_sql         #=> " where column1 = 10 and column2 = 'book'"
  def to_sql
    " where #{sql_parts.join(' and ')}"
  end
  
  def add_condition(lval, operator, rval) #:nodoc:
    sql_parts << "#{lval.to_sql} #{operator} #{rval.to_sql}"
  end
  
  def add_parenthesis_condition(lval, operator, rval) #:nodoc:
    sql_parts << "#{lval.to_sql} #{operator} (#{rval.to_sql})"
  end
  
  
  def add_clause(arg)
    sql_parts << arg
  end
  
  protected
  def sql_parts #:nodoc:
    @sql_parts ||= []
  end
  
  def method_missing(sym, *args) #:nodoc:
    super unless args.empty?
    ReceiveAny.new(sym, self)
  end
end