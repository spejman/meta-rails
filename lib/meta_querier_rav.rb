# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

require 'erb'
module MetaQuerier

  # Generates models diagram.
  class RailsApplicationVisualizer
    #DEFAULT_OPTIONS = { }
  
    # Creates a object for generate models diagram.
    #
    # Takes a *options* hash parameter that must have this value:
    # * :model_names => Array of model names (later .constantize will be applied to them)
    # * :model_columns => Hash with keys equal to model names (in .classify format), whose value
    #   is an array with the column names.
    # * :model_associations => The same as :model_columns but in each position the value is
    #   the associated models (in .classify format).
    # * :actual_model [OPTIONAL] => this model will be highlighted.
    #
    # Uses mq_diagram.dot.erb template in order to create de .dot file that Graphviz will
    # take for generate the diagram.
    def initialize(options = {})
      @options  = options #DEFAULT_OPTIONS.merge(options)
      template = File.read(File.dirname(__FILE__) + '/../files/mq_diagram.dot.erb')
  
      @dot = ERB.new(template).result(binding)
    end
  
    # Writes the diagram into given filenames. The format of the graph
    # is determined by the file extension. Tested formats (.png, .dot).
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
  
    def models #:nodoc:
      @options[:model_names].collect {|mn| mn.constantize }
    end
    
    def model_columns(model_name) #:nodoc:
      @options[:model_columns][model_name.to_s]
    end

    def model_associations(model_name) #:nodoc:
      @options[:model_associations][model_name.to_s]
    end
    
    def actual_model #:nodoc:
      @options[:actual_model]
    end
      
  end
end
