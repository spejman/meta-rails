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
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/add.png"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/remove.png"), destination)

# Directory to store the cache of db diagram images.
destination = File.join(RAILS_ROOT, "public/images/meta_rails/meta_querier")
FileUtils.mkdir(destination) unless File.exist?(destination)

# Meta querier migrations
puts "Generate and run migrations required to save queries ? (Recommended) [Y/n]"
resp = gets[0].chr
if  (resp == "y") || (resp == "\n")
  system("script/generate meta_querier_query_tables")
  system("rake db:migrate")
end

# Meta querier functional tests
# destination = File.join(RAILS_ROOT, "test/functional")
# FileUtils.mkdir(destination) unless File.exist?(destination)
# FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/meta_querier_controller_test.rb"), destination)