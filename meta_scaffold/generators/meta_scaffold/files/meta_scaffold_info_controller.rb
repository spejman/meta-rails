require "infer_db_model"
include MetaRails::InferDbModel

class MetaScaffoldInfoController < ApplicationController

  def index
    session[:profile] ||= "ALL"
    session[:profile] = params[:profile] if params[:profile]
    @avaliable_profiles = Dir["#{RAILS_ROOT}/db/metarails/*.yml"].collect{|pr| File.basename(pr)[0..-5]}

    if @avaliable_profiles.include? session[:profile]
      klasses_struct = YAML.load(File.open("#{RAILS_ROOT}/db/metarails/#{session[:profile]}.yml").read)
    else
      klasses_struct = klass_struct
    end

    @klasses_struct = klasses_struct

  end
end
