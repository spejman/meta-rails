require "sqldsl-1.4.2/sqldsl.rb"

require "rubygems"
require "active_support"
require "md5"


module MetaQuery
  DEFAULT_JOIN_TYPE = "left outer"
  DEFAULT_CODITION = "AND"
  
  class QueryException < Exception; end
  class CodeInjectionWarning < QueryException; end
end

%w(query model field condition).each {|lib| require "meta_query/#{lib}.rb"}
