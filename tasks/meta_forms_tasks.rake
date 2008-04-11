# desc "Explaining what the task does"
# task :meta_forms do
#   # Task goes here
# end


namespace :insert_example_data do
  
  desc "Populates DB with a Form for New Lexicon Entry"
  task(:form_new_lexicon => :environment) do
    form = MetaFormsForm.new(:name => "Crea tu propio Lexicon test", 
                            :description => "Ahora puedes crear tu propio lexicon",
                            :profile => "")
    
    
    lexicon_table = MetaFormsFormTable.new(
                        :table_name => "Lexicon",
                        :name => "Lexicon", 
                        :description => "A continuacion tendras que rellenar todos los parametros",
                        :hidden => false)

      lexicon_feat_table = MetaFormsFormTable.new(
                          :table_name => "LexiconFeat",
                          :name => "Nombre del lexicon", 
                          :description => "Tienes que darle un nombre, es obligatorio!",
                          :hidden => false)
        lexicon_feat_att = MetaFormsAttribute.new(
                            :attr_name => "value",
                            :name => "Nombre",
                            :description => "El nombre que le tienes que poner al lexicon",
                            :hidden => false,
                            :compulsory => true,
                            :default_value => "nombre por defecto",
                            :field_type => "string")
    
        lexicon_feat_table.table_attributes << lexicon_feat_att
        lexicon_feat_table.save
        lexicon_feat_att.save
    
        data_cat_table = MetaFormsFormTable.new(
                            :table_name => "DataCategory",
                            :name => "Data Category", 
                            :description => "Añade una datacategory al lexicon. (Nombre)",
                            :hidden => false)
        
          data_cat_att = []
          data_cat_att[0] = MetaFormsAttribute.new(
                        :attr_name => "xml_info",
                        :name => "xml info",
                        :description => "desc xml_info",
                        :hidden => true,
                        :compulsory => false,
                        :default_value => "default xml info data",
                        :field_type => "text")
          data_cat_att[1] = MetaFormsAttribute.new(
                        :attr_name => "name",
                        :name => "Nombre",
                        :description => "desc nombre",
                        :hidden => false,
                        :compulsory => true,
                        :default_value => "default name data",
                        :field_type => "string")
          data_cat_att[2] = MetaFormsAttribute.new(
                        :attr_name => "dcr_location",
                        :name => "dcr localizacion",
                        :description => "desc dcr localtion",
                        :hidden => false,
                        :compulsory => false,
                        :default_value => "",
                        :field_type => "string")               
          data_cat_att[3] = MetaFormsAttribute.new(
                        :attr_name => "registration_status",
                        :name => "estatus de registro",
                        :description => "desc status",
                        :hidden => false,
                        :compulsory => false,
                        :default_value => "",
                        :field_type => "string")   
          data_cat_att[4] = MetaFormsAttribute.new(
                        :attr_name => "profile",
                        :name => "",
                        :description => "",
                        :hidden => false,
                        :compulsory => false,
                        :default_value => "",
                        :field_type => "string") 
     
    
    data_cat_att.each do |item| 
      data_cat_table.table_attributes << item
      item.save
    end
    
    lexicon_feat_table.child_tables << data_cat_table
    lexicon_table.child_tables << lexicon_feat_table
    
    form.initial_table = lexicon_table
    
    data_cat_table.save
    lexicon_feat_table.save
    lexicon_table.save
    form.save
    
    
  end
  
end