META_QUERIER
============
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Install hook code here
RAILS_ROOT = "./" unless defined? RAILS_ROOT
require "fileutils"

# Meta querier CSS
destination = File.join(RAILS_ROOT, "public/stylesheets/meta_rails")
FileUtils.mkdir(destination) unless File.exist?(destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/meta_querier.css"), destination)

# Meta querier design icons and images.
destination = File.join(RAILS_ROOT, "public/images/meta_rails")
FileUtils.mkdir(destination) unless File.exist?(destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/cross.png"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/indicator.gif"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/ajax_indicator.gif"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/add.png"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/remove.png"), destination)

# Directory to store the cache of db diagram images.
destination = File.join(RAILS_ROOT, "public/images/meta_rails/meta_querier")
FileUtils.mkdir(destination) unless File.exist?(destination)

# Meta querier migrations
puts "Generating and running migrations required to save queries ..."
system("ruby script/generate meta_querier_query_tables")
system("rake db:migrate")
META_BULK_DATA
==============
# Install hook code here
META_FORMS
==========
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Install hook code here

# Meta forms migrations
puts "Generating and running migrations required for meta forms ..."
system("ruby script/generate meta_forms_tables")
system("rake db:migrate")

META_SCAFFOLD
=============
require "fileutils"
# Assume that RAILS_ROOT is current directory unless RAILS_ROOT is defined
# or exists the vendor/plugins/meta_scaffold path from current directory.
RAILS_ROOT = "." if (!defined?(RAILS_ROOT) && !Dir["vendor/plugins/meta_scaffold"].empty?)

# Install the css file
destination = File.join(RAILS_ROOT, "public/stylesheets/meta_rails")
FileUtils.mkdir(destination) unless File.exist?(destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_scaffold/generators/meta_scaffold/files/meta_scaffold.css"), destination)

destination = File.join(RAILS_ROOT, "db/metarails")
FileUtils.mkdir(destination) unless File.exist?(destination)

# Install ActiveScaffold if not already installed.
unless File.exists? File.join(RAILS_ROOT, "vendor/plugins/active_scaffold")
  puts "ActiveScaffold is not installed and is needed for MetaScaffold,\n \
         do you allow MetaScaffold to install them? (Y/n)"
  inst_conf = gets

  if inst_conf == "\n" or inst_conf.downcase == "y\n"
    puts "Installing ActiveScaffold plugin ..."
    system("ruby " + File.join(RAILS_ROOT, "script/plugin") + " install http://activescaffold.googlecode.com/svn/tags/active_scaffold")
    puts "ActiveScaffold plugin installed"
  end

end
META_WEB_SERVICES
=================
# Install hook code here
