#require 'config/environment.rb'

require 'erb'
module MetaQuerier
  class RailsApplicationVisualizer
    #DEFAULT_OPTIONS = { }
  
    def initialize(options = {})
      @options  = options #DEFAULT_OPTIONS.merge(options)
      template = File.read(File.dirname(__FILE__) + '/../mq_diagram.dot.erb')
  
      @dot = ERB.new(template).result(binding)
    end
  
    def output(*filenames)
      filenames.each do |filename|
        format = filename.split('.').last
        
        if format == 'dot'
          # dot supports -Tdot, but this makes debugging easier :-)
          File.open(filename, 'w') { |io| io << @dot }
          return true
        else
          IO.popen("dot -T#{format} -o #{filename}", 'w') { |io| io << @dot }                 
          return $?.success?
        end
      end
    end
  
    protected
  
    # These methods are called from diagram.dot.erb
  
    def models
      @options[:model_names].collect {|mn| mn.constantize }
    end
    
    def model_columns(model_name)
      @options[:model_columns][model_name.to_s]
    end

    def model_associations(model_name)
      @options[:model_associations][model_name.to_s]
    end

    
    def actual_model
      @options[:actual_model]
    end
      
  end
end
