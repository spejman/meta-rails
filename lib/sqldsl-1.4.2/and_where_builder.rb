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
    " and (#{sql_parts.join(' and ')})"
  end
end
