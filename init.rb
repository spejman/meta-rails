META_QUERIER
============
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Include hook code here
directory = "#{RAILS_ROOT}/vendor/plugins/meta_querier"

controller_path = File.join(directory, 'app', 'controllers')

$LOAD_PATH << controller_path
if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION >= '1.2.0'
  Dependencies.load_paths << controller_path
else
  raise "Engines plugin is needed for running meta_querier with a Ruby on Rails version < 1.2.0" if Dir["#{RAILS_ROOT}/vendor/plugins/engines"].empty?
end
config.controller_paths << controller_path

Mime::Type.register "image/png", :png unless defined? Mime::PNG
Mime::Type.register "application/pdf", :pdf unless defined? Mime::PDF
Mime::SET << Mime::CSV 
Mime::Type.register "text/csv", :csv unless defined? Mime::CSV
Mime::Type.register "application/excel", :xls unless defined? Mime::XLS
Mime::Type.register "text/tab-separated-values", :tsv unless defined? Mime::TSV

require "meta_querier"
META_BULK_DATA
==============
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Include hook code here
directory = "#{RAILS_ROOT}/vendor/plugins/meta_bulk_data"

controller_path = File.join(directory, 'app', 'controllers')

$LOAD_PATH << controller_path
if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION >= '1.2.0'
  Dependencies.load_paths << controller_path
else
  raise "Engines plugin is needed for running meta_querier with a Ruby on Rails version < 1.2.0" if Dir["#{RAILS_ROOT}/vendor/plugins/engines"].empty?
end
config.controller_paths << controller_path

require "meta_bulk_data"
META_FORMS
==========
# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

# Include hook code here
directory = "#{RAILS_ROOT}/vendor/plugins/meta_forms"

controller_path = File.join(directory, 'app', 'controllers')

$LOAD_PATH << controller_path
if defined?(RAILS_GEM_VERSION) and RAILS_GEM_VERSION >= '1.2.0'
  Dependencies.load_paths << controller_path
else
  raise "Engines plugin is needed for running meta_forms with a Ruby on Rails version < 1.2.0" if Dir["#{RAILS_ROOT}/vendor/plugins/engines"].empty?
end
config.controller_paths << controller_path

require "meta_forms"

META_SCAFFOLD
=============
# Include hook code here
require "meta_scaffold"META_WEB_SERVICES
=================
# Include hook code here
require "meta_scaffold"