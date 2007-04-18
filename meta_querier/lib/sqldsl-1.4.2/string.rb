class String
  # call-seq: string.to_sql -> a_string
  # 
  # Returns a string with single quotes escaped.
  # 
  #    :book.to_sql     #=> "book"
  def to_sql
    "'#{self.gsub(/'/, "''")}'"
  end
  
  # call-seq: string.as(alias_name) -> a_symbol
  # 
  # Returns the string aliased (including 'as') as the aliased name
  # 
  #    "book".as(:category)     #=> :"'book' as category"
  def as(alias_name)
    "#{self.to_sql} as #{alias_name}".to_sym
  end

end