#!/usr/bin/ruby
require "rubygems"
require "highline"

if RUBY_PLATFORM.include? "mswin32"
  raise "This script don't work in Windows"
end

plugin_names = %w{ meta_querier meta_web_services meta_scaffold }
# Check the directory
plugin_names.each {|plugin_name| raise "Incorrect directory" if Dir[plugin_name].empty? }
h = HighLine.new

release_all = h.agree("Release the #{plugin_names.size} plugins (#{plugin_names.join(", ")})? (say no will allow you to choose which plugin to release)")
release_msg = h.ask("Release message:"){|q| q.default = "Release #{Time.now.to_s}" }
subversion_user = h.ask("Subversion User:"){|q| q.default = "spejman" }

SVN_URL = "svn+ssh://#{subversion_user}@rubyforge.org/var/svn/meta-rails"
SVN_PLUGINS_URL = "#{SVN_URL}/plugins"
SVN_HEAD_URL = "#{SVN_URL}/HEAD"


plugin_names.each do |plugin_name|  
  next if !release_all and !h.agree("Release #{plugin_name}?")
  ["svn rm #{SVN_PLUGINS_URL}/#{plugin_name} -m \"#{release_msg}\"",
   "svn copy #{SVN_HEAD_URL}/#{plugin_name} #{SVN_PLUGINS_URL} -m \"#{release_msg}\""].each do |command|
    puts command
    system command
  end
end