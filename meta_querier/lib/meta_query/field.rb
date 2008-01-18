  module MetaQuery
  class Field
    attr_reader :column_name, :as_name, :field_type, :parent_model
    
    def initialize(column_name, as_name, field_type = nil, parent_model = nil)
      @column_name = column_name
      @as_name = as_name
      @field_type = field_type
      @parent_model = parent_model
    end
    
    def to_sql
      "#{parent_model.id}.#{column_name} as #{as_name}"
    end
  end
  end