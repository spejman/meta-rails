#!/usr/bin/ruby
%w( meta_querier meta_bulk_data meta_forms meta_scaffold meta_web_services ).each do |plugin|
	# subdirs
	%w( app/views  generators tasks lib test ).each do |subdir|
		Dir["#{plugin}/#{subdir}/*"].each do |file|
			# views dirs...
			puts "git mv #{file} #{file[plugin.size+1..-1]}" if File.directory? file
		end
	end

	# files
	%w( app/controllers app/helpers app/models tasks lib test  ).each do |subdir|
		Dir["#{plugin}/#{subdir}/*"].each do |file|
			# views dirs...
			puts "git mv #{file} #{file[plugin.size+1..-1]}" unless File.directory? file
		end
	end
	
	puts "Look at:"
	Dir["#{plugin}/*/**/*"].each {|v| puts v}

end
