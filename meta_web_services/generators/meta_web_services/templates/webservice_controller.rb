class <%= ws_name.camelize.pluralize %>Controller < ApplicationController
  wsdl_service_name '<%= ws_name.camelize.pluralize %>'

  web_service_scaffold :invoke

  def show(id)
    <%= klass %>.find id
  end

  def list
	<%= klass %>.find :all
  end

  def new(name, otracosa, otro_id)
	otro_id = nil if otro_id < 0
	raise "otro_id invalid" unless otro_id.nil? or Otro.find(otro_id)
	l = Lexicon.new(:name => name, :otracosa => otracosa, :otro_id => otro_id)
	l.save
	return l0
  end

  def update
  end

  def delete
  end
end