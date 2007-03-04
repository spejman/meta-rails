require 'erubis'

module Sql92
	SELECT = <<-'END'
    select *    	
    from /*!=model */
    /*!=where */;
	END
	INSERT = <<-'END'
    INSERT INTO /*!=model */ #etc
    ;
	END

	# otra posibilidad:
	def select
		 "select * from #{model} #{where};"
	end
	
	# otra posibilidad:
	Select__ = <<-'END'
    select *    	
    from /*!=model */
    where
    /*! @conditions.each do |cond|  */
    /*!= cond.conector + ' (' + cond.column + ' ' + cond.operator + ' ' + cond.value + ')' */
    /*!end*/;
	END
	
	def where
		return '' unless @conditions
		'where ' + @conditions.map {|cond| "#{cond.conector} (#{cond.column} #{cond.operator} #{cond.value})" }.join(" ")
	end
end

class QueryDef  
  class Condition
    attr_accessor :conector, :column, :operator, :value
    def initialize(conector, column, operator, value)
    	@conector = conector
    	@column = column
    	@operator = operator
    	@value = value
    end
  end

  attr_accessor :model, :join, :conditions
  def initialize(model)
  	@model = model
    @join = []
    @conditions = []
  end
  
  def where(column, operator, value, conector='OR')
  	conector = '' if @conditions.length == 0
  	@conditions << Condition.new(conector, column, operator, value)
  	self
  end
  
  def or(column, operator, value)
  	where(column, operator, value)
  end
  
  def and(column, operator, value)
  	where(column, operator, value, 'AND')  
  end

  def to_sql(target)
  	extend(target)
    render = Erubis::Eruby.new(target::SELECT, :pattern => '\/\*\! \*\/')
    render.result(binding)
  end

	# usando alternativa
  def to_sql2(target)
  	extend(target)
  	select
  end
end


qry = QueryDef.new(:Person)

qry.where('name', '>', "'jorge'").or('apellido', '=', "'cangas'")
puts qry.to_sql(Sql92)
puts qry.to_sql2(Sql92)

