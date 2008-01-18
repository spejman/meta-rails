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

require "meta_querier"
