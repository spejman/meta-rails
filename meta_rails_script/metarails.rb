#!/usr/bin/ruby

require "rubygems"
require "highline"
require "fileutils"
require "yaml"
require "active_support"

require "highline/import"
# disable colors in windows because not all the users
# have ANSI color sequences enabled.
if RUBY_PLATFORM.include? "mswin32"
  HighLine.use_color = false
end

environment = if ARGV[0] == "-d"; "HEAD"
              else; "plugins"; end

h = HighLine.new

h.say "<%= color('-'*80, :green) %>"
h.say "  <%= color('MetaRails Script', BOLD) %>"
h.say "    This is a alpha version of MetaRails script, only works with <%= color('MySQL', BOLD) %>\n    databases."
h.say "<%= color('-'*80, :green) %>"

app_name = h.ask "Aplication name:"
db_file = h.ask("Database file schema:") {|q| q.default = "#{app_name}.yml" }
raise "File #{db_file} don't exists" unless File.exists? db_file

create_3_databases = h.agree("Create different databases for development, test and production?")

# Get database data
db = {}
%w{production test development}.each do |db_type|
  db[db_type] = {}
  db[db_type]["database"] = h.ask("Database name for #{db_type}:") {|q| q.default = (db["production"]["database"] if db["production"]) || "#{app_name}" }
  db[db_type]["username"] = h.ask("Database username for #{db_type}:") {|q| q.default = (db["production"]["username"] if db["production"]) || "#{app_name}"}  
  db[db_type]["password"] = h.ask("Database Password for #{db_type}:") { |q| q.echo = "*"; q.default = "#{app_name}" }
  break unless create_3_databases
end

# Create databases and users
databases = create_3_databases ? %w{production test development} : %w{production}
if create_database = h.agree("Create database#{"s" if create_3_databases}?")
  db_priv_user = h.ask("Database user with rights for create databases:") {|q| q.default = "root"}
  db_priv_password = h.ask("Database password for #{db_priv_user}:") { |q| q.echo = "*" }
  
  databases.each do |db_type|
    h.say "<%= color('Creating #{db_type} database ...', :green) %>"
    system "mysqladmin -u #{db_priv_user} #{"--password="+db_priv_password if db_priv_password} create #{db[db_type]["database"]}"
  end

  if create_user = h.agree("Create user#{"s" if create_3_databases}?")
    databases.each do |db_type|
      h.say "<%= color('Creating #{db_type} user ...', :green) %>"
      create_user_sql = "GRANT ALL PRIVILEGES ON #{db[db_type]["database"]}.* TO '#{db[db_type]["username"]}'@'localhost'" \
        "IDENTIFIED BY '#{db[db_type]["password"]}';"
      system "mysql -u #{db_priv_user} #{"--password="+db_priv_password if db_priv_password} --execute=\"#{create_user_sql}\""
    end
  end
  
end
 
h.say "<%= color('Generating Ruby on Rails application', :green) %>"
if RUBY_PLATFORM =~ /mswin32/
  system("rails #{app_name} > metarails-win.log")
else
  system("rails #{app_name}")
end
Dir.chdir("#{app_name}")

installed_plugins = {}
%w{meta_querier meta_web_services meta_scaffold}.each do |plugin|
  next unless installed_plugins[plugin] = h.agree("Install #{plugin.humanize} plugin?")
  h.say "<%= color('Installing #{plugin} plugin ...', :green) %>"
  system("ruby #{File.join("script","plugin")} install svn://rubyforge.org/var/svn/meta-rails/#{environment}/#{plugin}")
end

if installed_plugins["meta_scaffold"]
  h.say "<%= color('Installing active_scaffold plugin ...', :green) %>"
  system("ruby #{File.join("script","plugin")} install http://activescaffold.googlecode.com/svn/tags/active_scaffold")  
end

# Create database.yml
h.say "<%= color('Creating config/database.yml file ...', :green) %>"
%w{test development}.each {|db_type| db[db_type] = "production"} unless create_3_databases
databases.each do |db_type|
  db[db_type]["adapter"] = "mysql"
  db[db_type]["host"] = "localhost"
end
FileUtils.rm File.join("config", "database.yml")
database_yml = File.open(File.join("config", "database.yml"), "w")
database_yml.write db.to_yaml
database_yml.close

# Check consistency of database clases
require 'vendor/plugins/meta_scaffold/lib/dtd_to_mscff_yaml.rb'
require 'vendor/plugins/meta_scaffold/lib/check_consistency.rb'

klasses_filename = File.join(".." , db_file)
klasses = YAML.load(File.open(klasses_filename)) if klasses_filename[-4..-1] == ".yml"
klasses = dtd_to_mscff_yaml(klasses_filename) if klasses_filename[-4..-1] == ".dtd"


# 1. Check that not collide with ruby reserved vars or modules names.
klasses_eq_reserved_words = check_for_reserved_words(klasses.keys)
raise "Models with names equals to reserved words: " + klasses_eq_reserved_words.join(", ") \
      unless klasses_eq_reserved_words.empty?
      
# 2. Check that RoR inflections are correct.
metarails_custom_inflections = [
        #"inflect.singular(/s$/i, '')", # fails "lexical_entry" <--> "lexical_entries"
        "inflect.singular(/ss$/i, 'ss')",
        "inflect.singular(/^s$/i, 's')",        
        "inflect.singular(/(n)ews$/i, '\1ews')"
        ]
Inflector.inflections do |inflect|
  eval metarails_custom_inflections.join("\n")
end

klasses_with_diff_sig_to_pl = check_for_incorrect_inflection(klasses.keys)
unless klasses_with_diff_sig_to_pl.empty?
  h.say "There are some classes in the #{db_file} file that don't works well with Ruby on Rails Inflector."
  h.say "Please give us the correct plural form for the next words:"
  correct_inflections = {}
  klasses_with_diff_sig_to_pl.each do |klass_name_singular|
    correct_inflections[klass_name_singular] = h.ask("Plural form of #{klass_name_singular}") {|q| q.default = klass_name_singular.pluralize }
    # fix the plural (seems to be a bug in the rails Inflector)
    correct_inflections[correct_inflections[klass_name_singular]] = correct_inflections[klass_name_singular]
  end
  
 inflections_file = File.open(File.join("config", "metarails_inflections.rb"), "w")
 inflections_file.write "Inflector.inflections do |inflect|\n"
  inflections_file.write metarails_custom_inflections.join("\n") + "\n"
  inflections_file.write correct_inflections.collect { |s,pl| "inflect.irregular '#{s.camelize}', '#{pl.camelize}'" }.join("\n") + "\n"   
  inflections_file.write correct_inflections.collect { |s,pl| "inflect.irregular '#{s.underscore}', '#{pl.underscore}'" }.join("\n")
 inflections_file.write "\nend\n"
 inflections_file.close

 environment_file = File.open(File.join("config", "environment.rb"), "a")
 environment_file.write "\n\n" + 'require File.join("#{RAILS_ROOT}/config","metarails_inflections.rb")' + "\n"
 environment_file.close
end


# Meta Scaffold
h.say "<%= color('Scaffolding with Meta Scaffold ...', :green) %>"
system("ruby #{File.join("script","generate")} meta_scaffold #{klasses_filename} active_scaffold")

# Meta Web Services
h.say "<%= color('Scaffolding with Meta Web Services ...', :green) %>"
system("ruby #{File.join("script","generate")} meta_web_services #{klasses_filename}")


#database_yml = <<-EOF
#<%= db_type %>:
#EOF
