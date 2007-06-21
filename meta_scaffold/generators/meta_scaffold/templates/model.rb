class <%= class_name.singularize.camelize %> < ActiveRecord::Base
	<% class_ass.each do |relation| -%>
	   <%= relation.keys[0] %> :<%= (relation.keys[0] == "belongs_to" || relation.keys[0] == "has_one" )? relation.values[0].tableize.singularize : relation.values[0].tableize %>
	<% end %>

  def to_label
    avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}
    if avaliable_profiles.include? MetarailsSingleton.current_profile
      klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{MetarailsSingleton.current_profile}.yml").read)
    else
      klasses_struct = klass_struct
    end

    label_to_eval = klasses_struct[self.class.to_s]["label"]
    if label_to_eval
      eval(label_to_eval) rescue "NOT AVALIABLE"
    else
      super
    end
  end

end
