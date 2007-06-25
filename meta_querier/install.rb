# Install hook code here
RAILS_ROOT = "./"
require "fileutils"

destination = File.join(RAILS_ROOT, "public/stylesheets/meta_rails")
FileUtils.mkdir(destination) unless File.exist?(destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/meta_querier.css"), destination)

destination = File.join(RAILS_ROOT, "public/images/meta_rails")
FileUtils.mkdir(destination) unless File.exist?(destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/cross.png"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/indicator.gif"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/add.png"), destination)
FileUtils.cp(File.join(RAILS_ROOT, "vendor/plugins/meta_querier/files/remove.png"), destination)

destination = File.join(RAILS_ROOT, "public/images/meta_rails/meta_querier")
FileUtils.mkdir(destination) unless File.exist?(destination)
