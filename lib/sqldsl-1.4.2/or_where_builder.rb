class OrWhereBuilder < WhereBuilder
  
  # call-seq: or_where.to_sql -> a_string
  # 
  # Returns a string by collecting all the conditions and joins them with ' and '.
  # 
  #    OrWhereBuilder.new [] do 
  #      equal :column1, 10
  #      equal :column2, 'book'
  #    end.to_sql         #=> " or (column1 = 10 and column2 = 'book')"
  def to_sql
    " or (#{sql_parts.join(' and ')})"
  end

end