# 
# xml_data_to_db_test.rb
# 
# Created on 03-oct-2007, 14:27:42
# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'

require "rubygems"
require "yaml"
require "active_support"
require File.dirname(__FILE__) + "/meta_rails_classes_for_testing.rb"
require File.dirname(__FILE__) + '/../lib/xml_data_to_db.rb'
include MetaRails::XmlDataToDb


class XmlDataToDbTest < Test::Unit::TestCase
    
  def test_foo
    # assert_equal("foo", bar)

    # assert, assert_block, assert_equal, assert_in_delta, assert_instance_of,
    # assert_kind_of, assert_match, assert_nil, assert_no_match, assert_not_equal,
    # assert_not_nil, assert_not_same, assert_nothing_raised, assert_nothing_thrown,
    # assert_operator, assert_raise, assert_raises, assert_respond_to, assert_same,
    # assert_send, assert_throws
  end
  
  def xml_data
    string = <<EOF
<?xml version="1.0" encoding="ISO-8859-15"?>
<Lexicon>
<LexicalEntry>
	<Feat att="partOfSpeech" val="verb"/>

<Lemma>
	<Feat att="writtenForm" val="test"/>													
</Lemma>													


<SyntacticBehaviour subcategorizationFrameSets="FS_TR_3.2"/>
</LexicalEntry>

<SubcategorizationFrameSet id="FS_TR_3.2" subcategorizationFrames="F_TR_3.2.1 F_TR_1.1"/>

<SubcategorizationFrame id="F_TR_1.1"/>
    
<SubcategorizationFrame id="F_TR_3.2.1">

<SyntacticArgument id="synArg_Sub_SN">
	<Feat att="function" val="subject"/>
	<Feat att="syntacticConstituent" val="NP"/>
</SyntacticArgument>

	<SyntacticArgument id="synArg_Ob_Inf_De">
		<Feat att="function" val="direct object"/>
		<Feat att="introducer" val="de"/>
		<Feat att="syntacticConstituent" val="OCompl"/>
	</SyntacticArgument>

</SubcategorizationFrame>
</Lexicon>
EOF

    return string
  end

  def correct_names
    { "Lexicon" => ["lexical_entries", "subcategorization_frame_sets", "subcategorization_frames"],
      "LexicalEntry" => ["feats", "lemma", "syntactic_behaviours"],
      "Feat" => ["att", "val"],
      "Lemma" => ["feats"],
      "SyntacticBehaviour" => ["subcategorizationFrameSets".underscore],
      "SubcategorizationFrameSet" => ["id", "subcategorizationFrames".underscore], 
      "SubcategorizationFrame" => ["id", "syntactic_arguments"],
      "SyntacticArgument" => ["id", "feats"]}.sort
  end

  
  def klass_struct
    YAML.load(File.open(File.join(File.dirname(__FILE__),'klass_struct.yml')).read)
  end
  
  def test_insert_xml_data_into_db
    
    root_obj = insert_xml_data_into_db(Document.new(xml_data).root, klass_struct)
    
    assert_equal Lexicon, root_obj.class, "Incorrect root object"
    assert root_obj.saved?, "Root class not saved"
    assert_equal LexicalEntry, root_obj.lexical_entries.first.class, "Incorrect first class"
    assert_equal 1, root_obj.lexical_entries.size, "Incorrect number of lexical entries"
    
    lexical_entry = root_obj.lexical_entries.first
    assert lexical_entry.saved?, "Object not saved. Error saving 1st level objects."
    assert_equal Feat, lexical_entry.feats.first.class, "Error with has_many relations"
    assert_equal 1, lexical_entry.feats.size, "Error with has_many relations"
    assert_equal "partOfSpeech", lexical_entry.feats.first.att, "Error assigning attribute values"
    assert_equal "verb", lexical_entry.feats.first.val, "Error assigning attribute values"
    assert_equal root_obj, lexical_entry.lexicon
    
    assert_equal Lemma, lexical_entry.lemmas.first.class, "Error with has_many relations"
    assert_equal 1, lexical_entry.lemmas.size, "Error with has_many relations"
    assert_equal "writtenForm", lexical_entry.lemmas.first.feats.first.att, "Error assigning attribute values"
    assert_equal "test", lexical_entry.lemmas.first.feats.first.val, "Error assigning attribute values"
    
    assert_equal SyntacticBehaviour, lexical_entry.syntactic_behaviours.first.class
    assert_equal 1, lexical_entry.syntactic_behaviours.size
    
    syntactic_behaviour = lexical_entry.syntactic_behaviours.first
    assert_equal SubcategorizationFrameSet, syntactic_behaviour.subcategorization_frame_sets.first.class
    assert_equal 1, syntactic_behaviour.subcategorization_frame_sets.size, "Error with has_many relations"
    
    sfs = syntactic_behaviour.subcategorization_frame_sets.first    
    assert_equal "FS_TR_3.2", sfs.identifier, "Error getting the ids"
    assert_equal SubcategorizationFrame, sfs.subcategorization_frames.first.class
    assert_equal 2, sfs.subcategorization_frames.size, "Error with has_many relations taken usign ids relations"
    assert_equal root_obj, sfs.lexicon
    
    sf_1_1 = sfs.subcategorization_frames.select {|sf| sf.identifier == "F_TR_1.1" }.first
    assert_not_nil sf_1_1
    assert_empty sf_1_1.syntactic_arguments, "Error assigning related objects to empty relations"
    assert_equal root_obj, sf_1_1.lexicon
    
    sf_3_2_1 = sfs.subcategorization_frames.select {|sf| sf.identifier == "F_TR_3.2.1" }.first
    assert_not_nil sf_3_2_1
    assert_equal 2, sf_3_2_1.syntactic_arguments.size, "Error assing multiple related objects inside the parent tags"
    assert_equal SyntacticArgument, sf_3_2_1.syntactic_arguments.first.class, "Error assing multiple related objects inside the parent tags"
    assert_equal root_obj, sf_3_2_1.lexicon
    
    sa_sub_sn = sf_3_2_1.syntactic_arguments.select {|sa| sa.identifier == "synArg_Sub_SN"}.first
    assert_not_nil sa_sub_sn
    assert_equal 2, sa_sub_sn.feats.size, "Error assing multiple related objects inside the parent tags"
        
    sa_ob_inf_de = sf_3_2_1.syntactic_arguments.select {|sa| sa.identifier == "synArg_Ob_Inf_De"}.first
    assert_not_nil sa_ob_inf_de
    assert_equal 3, sa_ob_inf_de.feats.size, "Error assing multiple related objects inside the parent tags"
    assert_equal [["function", "direct object"], ["introducer", "de"], ["syntacticConstituent", "OCompl"]], sa_ob_inf_de.feats.collect {|f| [f.att, f.val]}.sort_by{|i| i[0]}
    
  end
  
  def assert_empty(array, message = nil)
    assert array.empty?, message
  end
  
  def test_check_if_xml_is_consistent_with_db
    
    names = []
    assert_nothing_raised do # Correct XML and klass_struct      
      names = check_if_xml_is_consistent_with_db(Document.new(xml_data).root, klass_struct)
    end
    # Check for the check_if_xml_is_consistent_with_db output value
    assert_equal correct_names, names.sort, "check_if_xml_is_consistent_with_db output error"
    
    klass_struct_without_feats_attr = klass_struct
    klass_struct_without_feats_attr["Feat"]["class_attr"] = {}
    klass_struct_without_syntactic_argument = klass_struct
    klass_struct_without_syntactic_argument.delete "SyntacticArgument"

    assert_raises AttributeNotExist do
      check_if_xml_is_consistent_with_db(Document.new(xml_data).root, klass_struct_without_feats_attr)
    end
    
    assert_raises ClassNotExist do
      check_if_xml_is_consistent_with_db(Document.new(xml_data).root, klass_struct_without_syntactic_argument)
    end
    
  end
  
  def test_check_if_xml_is_consistent_with_its_ids
    assert_nothing_raised do
      check_if_xml_is_consistent_with_its_ids(Document.new(xml_data).root, klass_struct)
    end
    
    # Remove an Id to raise IdNotExist exception
    doc = Document.new(xml_data)
    doc.root.elements[3].remove
    assert_raises IdNotExist do
      check_if_xml_is_consistent_with_its_ids(doc.root, klass_struct)
    end
    
  end
  
  def test_get_xml_model_attr_with_ids
    model_attr_with_ids = {"subcategorization_frame_set"=>["FS_TR_3.2"], "subcategorization_frame"=>["F_TR_3.2.1", "F_TR_1.1"]}
    assert_equal model_attr_with_ids, get_xml_model_attr_with_ids(Document.new(xml_data).root, klass_struct)
  end
  
  def test_get_xml_model_ids
    model_ids = {"subcategorization_frame_set"=>["FS_TR_3.2"],
      "subcategorization_frame"=>["F_TR_1.1", "F_TR_3.2.1"],
      "syntactic_argument"=>["synArg_Sub_SN", "synArg_Ob_Inf_De"]}    
    assert_equal model_ids, get_xml_model_ids(Document.new(xml_data).root)
    
  end
  
  
end
