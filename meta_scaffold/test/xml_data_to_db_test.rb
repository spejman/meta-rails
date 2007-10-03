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
require '../lib/xml_data_to_db.rb'
include REXML
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

  def klass_struct
    YAML.load(File.open(File.join(File.dirname(__FILE__),'klass_struct.yml')).read)
  end
  
  def test_check_if_xml_is_consistent_with_db
    
    #check_if_xml_is_consistent_with_db(Document.new("<x></x>").root, {"x" => []})
    assert_nothing_raised do 
      check_if_xml_is_consistent_with_db(Document.new(xml_data).root, klass_struct)
    end
      klass_struct_without_feats_attr = klass_struct
      klass_struct_without_feats_attr["Feat"]["class_attr"] = {}
      assert_raises MetaRailsError do
        check_if_xml_is_consistent_with_db(Document.new(xml_data).root, klass_struct_without_feats_attr)
      end
  end
end
