require File.join(File.dirname(__FILE__), "infer_db_model.rb")

module MetaRails
  
  # returns the path to the meta_rails plugin layout
  def select_layout(plugin_override_template = nil)
    layout_dir = File.join RAILS_ROOT, "app", "views", "layouts"
    if template_root.include? "vendor/plugins"
      default_layout_dir = File.join "../"*5, "app", "views", "layouts"
    else
      default_layout_dir = template_root
    end
    
    #FIXME: make rails 2.0 compliant (meta_rails.html.erb)
    return File.join(default_layout_dir, plugin_override_template) if plugin_override_template \
      && File.exists?(File.join(layout_dir, "#{plugin_override_template}.rhtml"))

    return File.join(default_layout_dir, "meta_rails") if File.exists? File.join(layout_dir, "meta_rails.rhtml")

    return "application"
  end
  
end