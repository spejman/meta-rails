require "fileutils"

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
