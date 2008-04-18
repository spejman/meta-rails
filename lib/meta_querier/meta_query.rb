# Meta Query is a structure that is used by MetaQuerier for store the query
# and finally generate the sql needed to execute this query.

require "active_support"
require "md5"
require "sqldsl-1.4.2/sqldsl.rb"

module MetaQuery
  DEFAULT_JOIN_TYPE = "left outer"
  DEFAULT_CODITION = "AND"
  
  class QueryException < Exception; end
  class CodeInjectionWarning < QueryException; end
end

# Load meta query components
%w(query model field condition).each {|lib| require "meta_query/#{lib}.rb"}
