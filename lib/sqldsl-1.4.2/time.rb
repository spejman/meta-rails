class Time
  # call-seq: time.to_sql -> a_string
  # 
  # Returns a string that represents a database agnostic time.
  # 
  #    Time.at(946702800).to_sql     #=> "to_timestamp('2000-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')"
  def to_sql
    "to_timestamp('" + formatted + "', 'YYYY-MM-DD HH24:MI:SS')"
  end
  
  protected
  
  def formatted #:nodoc:
    "#{year.to_s}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(min)}:#{pad(sec)}"
  end
  
  def pad(num) #:nodoc:
    num.to_s.rjust(2,'0')
  end
end