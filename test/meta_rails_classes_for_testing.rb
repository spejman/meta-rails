# 
# active_record_without_database.rb
# 
# Created on 15-oct-2007, 10:59:27
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 
require "active_support"

class ActiveRecordWithoutDatabase
  attr_accessor :identifier
  attr_internal_accessor :saved
  
  def attributes
    attr = self.methods.select {|m| m[-1..-1] == "="}
    attr -= [ "==", "===", "taguri="]
    attr.collect!{|m| m[0..-2]}
  end
  
#  def self.has_and_belongs_to_many(name)
#    @@habtm ||= {}
#    @@habtm[name.to_s] = []
#  end
#  def self.habtm(name); self.has_and_belongs_to_many(name); end
#
#  def self.has_many(name)
#    #eval "def #{name}(value); @#{name}||=[]; return @#{name}; end"
#  end
#
#  def self.belongs_to(name)
#    @@belongs_to ||= {}
#    @@belongs_to[name.to_s] = nil
#  end
#
#  def self.has_one(name)
#    @@has_one ||= {}
#    @@has_one[name.to_s] = nil
#  end
#  
  def save
     @saved = true
     #p self
     own_rel_name = self.class.to_s.pluralize.underscore
     attributes.each do |attr|
       rel = self.send(attr.to_sym)
       if rel.methods.include? own_rel_name
        rel_array = rel.send(own_rel_name.to_sym)
        raise "Array for class #{rel.class.to_s} and relation #{attr}.#{own_rel_name} is nil (not initialized)" unless rel_array
        rel_array << self unless rel_array.include? self
       end
     end
  end
  
  def saved?; return @saved; end
  
  def initialize
    @saved = false
  end
  
#  def method_missing(symbol, *args)
##    
##    if @habtm.keys.include? symbol.to_s
##      return @habtm[symbol.to_s].send(args)
##    elsif @has_many.keys.include? symbol.to_s
##      return @has_many[symbol.to_s].send(args)
##    elsif @belongs_to.keys.include? symbol.to_s
##      return @belongs_to[symbol.to_s].send(args)
##    elsif @has_one.keys.include? symbol.to_s
##      return @has_one[symbol.to_s].send(args)
##    end
##
##    
##    
#    if symbol.to_s.include? "="
#      
#      new_symbol = symbol.to_s.gsub("=", "")
#      eval("#{new_symbol} = #{args}")
#    end
#    
#    super(symbol, *args)
#  end
#  
end

class HackActiveRecordArray < Array
  
  def initialize(parent)
    @parent = parent
    super
  end
  
  def <<(obj)
    super
    obj.class.to_s.pluralize.underscore
  end
  
end

# Classes for testing
  class Lexicon < ActiveRecordWithoutDatabase
    attr_accessor :lexical_entries, :subcategorization_frame_sets, :subcategorization_frame, :syntactic_arguments

    def initialize
      @lexical_entries = []
      @subcategorization_frame_sets = []
      @subcategorization_frames = []      
      super
    end
  end

  class LexicalEntry < ActiveRecordWithoutDatabase
    attr_accessor :feats, :syntactic_behaviours, :lemmas, :lexicon
    def initialize
      @feats = []
      @syntactic_behaviours = []
      @lemmas = []
      super
    end
  end

  class Lemma < ActiveRecordWithoutDatabase
    attr_accessor :feats, :lexical_entry
    def initialize
      @feats = []
      super
    end
  end
  class Feat < ActiveRecordWithoutDatabase; attr_accessor :att, :val, :lexical_entry, :lemma, :syntactic_argument; end
  class SyntacticBehaviour < ActiveRecordWithoutDatabase;
    attr_accessor :subcategorization_frame_sets, :lexical_entry
    def initialize
      @subcategorization_frame_sets = []
      super
    end
  end
  class SubcategorizationFrameSet < ActiveRecordWithoutDatabase
    attr_accessor :subcategorization_frames, :lexicon
    def initialize
      @subcategorization_frames = []
      super
    end
  end
  class SubcategorizationFrame < ActiveRecordWithoutDatabase
    attr_accessor :lexicon, :syntactic_arguments
    def initialize
      @syntactic_arguments = []
      super
    end
  end
  class SyntacticArgument < ActiveRecordWithoutDatabase
    attr_accessor :lexicon, :subcategorization_frame, :feats
    def initialize
    @feats = []
    super
    end
  end
 