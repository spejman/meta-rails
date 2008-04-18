class OnWhereBuilder < WhereBuilder
  
  # call-seq: on_where.to_sql -> a_string
  # 
  # Returns a string by collecting all the conditions and joins them with ' and '.
  # 
  #    OnWhereBuilder.new [] do 
  #      equal :column1, 10
  #      equal :column2, 'book'
  #    end.to_sql         #=> " on column1 = 10 and column2 = 'book'"
  def to_sql
    " on #{sql_parts.join(' and ')}"
  end

end