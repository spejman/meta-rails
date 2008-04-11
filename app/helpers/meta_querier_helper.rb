# Author::    Sergio Espeja
# Copyright:: Copyright (c) 2007 Sergio Espeja
# License::   GPL License
# More Information:: http://meta-rails.rubyforge.org

module MetaQuerierHelper
  
  def options_for_select_condition_operations(data_type = :string)
    common_data_type_ops = %w( == <=> > < >= <= )
    data_type_ops = common_data_type_ops
    if (data_type == "string") || (data_type == :string)
      data_type_ops += %w( =~ )
    end
    return options_for_select(data_type_ops)
  end
  
  def dom_id(obj)
    if obj.class == String
      obj
    else
      "#{obj.id}"
    end
  end
  
  def css_class(name, text = nil , &block)
    if block_given?
      content = capture(&block)
      content_tag = content_tag_string(:span, content, {:class => name.to_s})
      concat(content_tag, block.binding)
    else
      content_tag(:span, text, :class => name.to_s)
    end
  end
  
  def print_size(array, name = nil)
    if name
      array.size.to_s + " " + ( (array.size == 1) ? name.singularize : name.pluralize)
    else
      array.size # unless array.empty?  
    end
  end
  
  
end
