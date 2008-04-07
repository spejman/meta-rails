class ReceiveAny < BlankSlate #:nodoc:
  attr_reader :to_sql, :builder
  
  def initialize(identifier, builder)
    @to_sql = identifier.to_s
    @builder = builder
  end
  
  def equal(arg)
    builder.equal self, arg
  end
  alias == equal
  
  def not_equal(arg)
    builder.not_equal self, arg
  end
  alias <=> not_equal
  
  def less_than(arg)
    builder.less_than self, arg
  end
  alias < less_than
  
  def less_than_or_equal(arg)
    builder.less_than_or_equal self, arg
  end
  alias <= less_than_or_equal
  
  def greater_than(arg)
    builder.greater_than self, arg
  end
  alias > greater_than
  
  def greater_than_or_equal(arg)
    builder.greater_than_or_equal self, arg
  end
  alias >= greater_than_or_equal
  
  def is_in(arg)
    builder.is_in self, arg
  end
  alias >> is_in
  
  def is_not_in(arg)
    builder.is_not_in self, arg
  end
  alias << is_not_in

  def like(arg)
    builder.like self, arg
  end
  alias =~ like
  
  def is_not_null(arg=nil)
    builder.is_not_null self
  end
  alias ^ is_not_null
  
  def method_missing(sym, *args)
    #raise ArgumentError.new("#{self.to_sql} is not specified as a table in your from statement") unless @builder.tables.include?(self.to_sql.to_sym)
    @to_sql << ".#{sym.to_s}"
    self
  end
end