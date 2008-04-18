require "infer_db_model"

module MetaRails
  
  # Returns the path to the meta_rails plugin layout
  # The search order is:
  # 1. template_root/plugin_override_template
  # 2. RAILS_ROOT/app/views/layouts/meta_rails.rhtml
  # 3. template_root/layouts/meta_rails.rhtml
  # 4. template_root/layouts/application.rhtml
  def select_layout(plugin_override_template = nil)
    if template_root.include? "vendor/plugins"
      default_layout_dir = File.join "../"*5, "app", "views", "layouts"
    else
      default_layout_dir = template_root
    end

    #FIXME: make rails 2.0 compliant (meta_rails.html.erb)
    return File.join(default_layout_dir, plugin_override_template) if plugin_override_template \
      && File.exists?(File.join(default_layout_dir, "#{plugin_override_template}.rhtml"))
    #FIXME: make rails 2.0 compliant (meta_rails.html.erb)
    return File.join(default_layout_dir, "meta_rails") if File.exists?(File.join(template_root, default_layout_dir, "meta_rails.rhtml"))
    #FIXME: make rails 2.0 compliant (meta_rails.html.erb)
    return "meta_rails" if File.exists?(File.join(template_root, "layouts", "meta_rails.rhtml"))
    return "application"
    
  end
  
end
