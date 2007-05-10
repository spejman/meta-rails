##
##
## THIS IS A TEST, DON'T WORK AS EXPECTED!!!
##

class InferController < ApplicationController

#  self.template_root = "#{RAILS_ROOT}/vendor/plugins/meta_scaffold/app/views/"  
  layout "meta_scaffold"
  
#  alias_method :old_method_missing, :method_missing
  
  def do_scaff(m_name)
#    render :text => "So advanced!!" + m_name.to_json + " params: " + params.to_json
#    alias_method :method_missing, :klass_method_missing
#    alias_method :old_method_missing, :method_missing
    ApplicationController.active_scaffold m_name[0].to_sym
#    alias_method :old_method_missing, :method_missing
#    alias_method :klass_method_missing, :method_missing
    #if defined? self.index
      self.send (params[:id] || "index")
    #else
    #  render :text => "no va"
    #end
  end

  def method_missing(*m_name)
    do_scaff(m_name)
  end
end