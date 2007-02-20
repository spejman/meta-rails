module MegaQuerierHelper

def search_model_in_query(query, route)
  route ||= []
  return query.select {|aq| aq[:model] == route[0] }[0] if route.size == 1
  actual_node = route.shift  
  search_model_in_query(query.select {|aq| aq[:model] == actual_node }[0][:join], route)
end

end
