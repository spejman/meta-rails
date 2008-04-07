class Numeric
  # call-seq: numeric.to_sql -> a_numeric
  # 
  # Returns self
  # 
  #    10.to_sql     #=> 10
  def to_sql
    self
  end
  
  # call-seq: numeric.as(alias_name) -> a_symbol
  # 
  # Returns the number aliased (including 'as') as the aliased name
  # 
  #    10.as(:column1)     #=> :"10 as column"
  def as(alias_name)
    "#{self} as #{alias_name}".to_sym
  end
end