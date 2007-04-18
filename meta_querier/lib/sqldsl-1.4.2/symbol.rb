class Symbol
  # call-seq: symbol.to_sql -> a_string
  # 
  # Returns a string with single quotes escaped.
  # 
  #    "it's".to_sql     #=> "'it''s'"
  def to_sql
    to_s
  end
  
  # call-seq: symbol.as(alias_name) -> a_symbol
  # 
  # Returns the symbol aliased (including 'as') as the aliased name
  # 
  #    :book.as(:category)     #=> :"book as category"
  def as(alias_name)
    "#{self} as #{alias_name}".to_sym
  end

end