# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Install hook code here

# Meta forms migrations
puts "Generating and running migrations required for meta forms ..."
system("ruby script/generate meta_forms_tables")
system("rake db:migrate")

