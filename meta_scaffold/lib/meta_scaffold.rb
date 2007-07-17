# MetaScaffold
#require "infer_models"
#require "infer_scaffold"

module MetaRails
  module MetaScaffoldModelBaseMethods
    
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
end