class DistinctSelect < Select #:nodoc:
  class << self
    def [](*columns)
      self.new("select distinct #{columns.to_sql}")
    end
  end
end