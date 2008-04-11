class Array
  # call-seq: array.to_sql -> a_string
  # 
  # Returns a string by collecting all elements, calling +to_sql+ on each one, and 
  # then joins them with ', '.
  # 
  #    [10, 'book', :column2].to_sql     #=> "10, 'book', column2"
  def to_sql
    self.collect { |element| element.to_sql }.join(', ')
  end
end