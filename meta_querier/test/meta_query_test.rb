# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'meta_query'

class MetaQueryTest < Test::Unit::TestCase
  
  def setup
    create_query
    create_real_query
  end
  
  def create_query
    @query = MetaQuery::Query.new
    @model_00 = @query.add_model(nil, "model[0,0]", [0,0])
    @model_01 = @query.add_model(nil, "model[0,1]", [0,1])
    @model_11 = @query.add_model(@model_00.id, "model[1,1]", [1,1])    
    @model_12 = @query.add_model(@model_11.id, "model[1,2]", [1,2])
    
    @fields_00 = []
    @fields_00 << @query.add_field(@model_00.id, "col_1_model_00", "as_col_1_model_00")
    @fields_00 << @query.add_field(@model_00.id, "col_2_model_00", "as_col_2_model_00")
    
    @conditions_11 = []
    @conditions_11 << @query.add_condition(@model_11.id, "col_1_model_11", "==", "33")
    @conditions_11 << @query.add_condition(@model_11.id, "col_1_model_11", "!=", "88", "OR")
    
    @all_models = [@model_00, @model_01, @model_11, @model_12]
  end
  
  def create_real_query
    @real_query = MetaQuery::Query.new
    @m_lexicon = @real_query.add_model(nil, "Lexicon", [0,0],
        {"label" => "string"}, {:has_many => ["lexical_entries"]})
    @m_le = @real_query.add_model(@m_lexicon.id, "LexicalEntry", [0,0],
        {"identifier" => "string"}, {:belongs_to => ["lexicon"]})
    
    @real_query.add_field(@m_le.id, "identifier", "nombre")
    @real_query.add_field(@m_lexicon.id, "label", "lexicon")    
    
    @real_query.add_condition(@m_lexicon.id, "label", "==", "RAE")
    
    @real_habtm_query = MetaQuery::Query.new
    @m_habtm_lexicon = @real_habtm_query.add_model(nil, "Lexicon", [0,0],
        {"label" => "string"}, {:has_and_belongs_to_many => ["lexical_entries"]})
    @m_habtm_le = @real_habtm_query.add_model(@m_habtm_lexicon.id, "LexicalEntry", [0,0],
        {"identifier" => "string"}, {:has_and_belongs_to_many => ["lexicon"]})
    
    @real_habtm_query.add_field(@m_habtm_le.id, "identifier", "nombre")
    @real_habtm_query.add_field(@m_habtm_lexicon.id, "label", "lexicon")    

  end
  
  def test_to_sql
    expected_sql = "select #{@m_lexicon.id}.label as lexicon, #{@m_le.id}.identifier as nombre " \
                 + "from #{@m_lexicon.table_name} #{@m_lexicon.id} " \
                 + "inner join #{@m_le.table_name} #{@m_le.id} on " \
                 + "#{@m_lexicon.id}.id = #{@m_le.id}.lexicon_id " \
                 + "where #{@m_lexicon.id}.label = 'RAE'"
    #assert_equal expected_sql, @real_query.to_sql
    
    real_query_plus_conds = @real_query.dup
    real_query_plus_conds.add_condition(@m_lexicon.id, "label", "<=>", "RAE", "OR")
    real_query_plus_conds.add_condition(@m_lexicon.id, "label", "=~", "%RAE%", "AND")
    expected_sql += " or (#{@m_lexicon.id}.label <> 'RAE') "
    expected_sql += "and (#{@m_lexicon.id}.label like '%RAE%')"
    #assert_equal expected_sql, real_query_plus_conds.to_sql
    
    expected_habtm_sql = "select #{@m_habtm_lexicon.id}.label as lexicon, #{@m_habtm_le.id}.identifier as nombre " \
                 + "from #{@m_habtm_lexicon.table_name} #{@m_habtm_lexicon.id} " \
                 + "inner join #{@m_habtm_le.table_name}_#{@m_habtm_lexicon.table_name} #{@m_habtm_lexicon.id + @m_habtm_le.id} on " \
                 + "#{@m_habtm_lexicon.id}.id = #{@m_habtm_lexicon.id + @m_habtm_le.id}.lexicon_id " \
                 + "inner join #{@m_le.table_name} #{@m_le.id} on " \
                 + "#{@m_habtm_lexicon.id + @m_habtm_le.id}.lexical_entry_id = #{@m_habtm_le.id}.id"
    assert_equal expected_habtm_sql, @real_habtm_query.to_sql

  end
  
  def test_model_ids
    query = MetaQuery::Query.new
    model_00 = query.add_model(nil, "model[0,0]", [0,0])
    assert_equal "model[0,0]_0_0", model_00.id, "Root model identifier incorrect"
    
    model_01 = query.add_model(nil, "model[0,1]", [0,1])
    assert_equal "model[0,1]_0_1", model_01.id, "Model identifier incorrect"

    model_11 = query.add_model(model_00.id, "model[1,1]", [1,1])
    assert_equal "model[0,0]_0_0_model[1,1]_1_1", model_11.id, "Model identifier incorrect"
    
    model_12 = query.add_model(model_11.id, "model[1,2]", [1,2])
    assert_equal "model[0,0]_0_0_model[1,1]_1_1_model[1,2]_1_2", model_12.id, "Model identifier incorrect"    
    
    assert_raise MetaQuery::QueryException do 
      query.add_model(model_11.id, "model[1,2]", [1,2])
    end
  end
  
  def test_each_model
    all_models = @all_models.dup
    assert_equal @all_models, all_models, "Error doing array.dup"
    assert_equal false, all_models.empty?, "all_models test variable empty!"
    @query.each_model do |model|
      all_models -= [model]
    end
    assert_equal true, all_models.empty?, "query.each_model didn't find all the models in query."
  end
  
#  FIXME: Can't be executed because all_fields_sql is a private method
#  def test_all_fields_sql    
#    expected_all_fields_sql = @fields_00.collect do |field|
#      "#{@model_00.id}.#{field.column_name} as #{field.as_name}"
#    end
#    assert_equal expected_all_fields_sql, @query.all_fields_sql, "query.all_fields doesn't behave as expected"    
#  end
  
  def test_remove_model
    query_to_delete = @query.dup
    models = query_to_delete.models
    models.each do |model|
      query_to_delete.remove_model model
      assert_equal false, query_to_delete.models.include?(model), "remove_model doesn't remove the element #{model.id}"
    end
    
    assert_equal true, query_to_delete.models.empty?, "remove_model doesn't remove all the elements"
    assert_equal true, query_to_delete.root.empty?, "remove_model doesn't remove all the ROOT elements"
  end
  
  def test_all_from_tables
    expected_all_from_tables = [["model[0,0]s","model[0,0]_0_0"], ["model[0,1]s","model[0,1]_0_1"]]
    assert_equal expected_all_from_tables, @query.all_from_tables, "query.all_from_tables doesn't behave as expected"
    
    query_1_root = @query.dup
    query_1_root.remove_model @model_01.id
    expected_all_from_tables = [["model[0,0]s","model[0,0]_0_0"]]
    assert_equal expected_all_from_tables, query_1_root.all_from_tables, "query.all_from_tables doesn't behave as expected"

  end
  
  def test_check_for_code_injection
    query = @real_query.dup
    query.add_condition(@m_lexicon.id, "label", "<=>", "a; raise 'hacker inside'; ", "OR")
    assert_raise(MetaQuery::CodeInjectionWarning) do
      query.to_sql
    end
    
  end
  
  def test_dump_and_load
    q_dump = @real_query.dump
    loaded_real_query = @real_query.load q_dump
    assert_equal @real_query.to_sql, loaded_real_query.to_sql    
  end
  
end
