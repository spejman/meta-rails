require "metarails"
require "singleton"

module MetaRails
  module MetaScaffold
    module ControllerMethods
      include MetaRails::InferDbModel
      
      def set_profile
        MetaRails::MetaScaffold::Singleton.current_profile = session[:profile]
      end
    
      def clear_profile
        MetaRails::MetaScaffold::Singleton.current_profile = nil
      end
  

      def actualize_profile_selected
        session[:profile] ||= "ALL"
        session[:profile] = params[:profile] if params[:profile]
        @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}
  
        flash[:notice] = ""
        if @avaliable_profiles.include? session[:profile]
          flash[:notice] = "Profile changed"
          klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
        else
          session[:profile] = "ALL"
          flash[:notice] = "Profile #{params[:profile]} doesn't exist using default profile #{session[:profile]}"
          klasses_struct = klass_struct
        end
        @klasses_struct = klasses_struct
      end
    
      def set_meta_scaffold_class_name
        # "MetaScaffoldModels::LexiconsController" --> Lexicon
        meta_scaffold_class_name = self.class.to_s[20..-11].classify
        @meta_scaffold_class_name = meta_scaffold_class_name

        actualize_profile_selected
        klasses_struct = @klasses_struct
  
        unless klasses_struct.keys.include? meta_scaffold_class_name
          render :text => "<center>#{meta_scaffold_class_name} is not a valid model for profile #{session[:profile]}.</center>", :layout => "meta_scaffold"
        else    
          desired_columns = klasses_struct[meta_scaffold_class_name]["class_ass"].collect { |pair| pair.values[0].to_sym }
          desired_columns += klasses_struct[meta_scaffold_class_name]["class_attr"].keys.collect(&:to_sym) if klasses_struct[meta_scaffold_class_name]["class_attr"]
          self.active_scaffold_config.configure do |conf|
            #conf.list.label = desired_columns.collect(&:to_s).join(",")
            actual_cols = []; conf.list.columns.each{|c| actual_cols << c.name}
            un_used_columns = actual_cols - desired_columns
            conf.list.columns.exclude(un_used_columns)
            conf.show.columns.exclude(un_used_columns)
            conf.update.columns.exclude(un_used_columns)
            conf.create.columns.exclude(un_used_columns)  
            conf.subform.columns.exclude(un_used_columns)  
          end
        end
      
      end
      
    end
  end
end