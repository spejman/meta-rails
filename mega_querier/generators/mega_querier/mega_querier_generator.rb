class MegaQuerierGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      files_to_copy = [ "app/controllers/mega_querier_controller.rb", 
      "app/views/mega_querier/index.rhtml", "app/views/mega_querier/_make_query.rhtml",
      "app/views/mega_querier/_query_builder_model.rhtml", "app/helpers/mega_querier_helper.rb",
      "public/stylesheets/mega_querier.css" ]
      m.directory "app/views/mega_querier"

      files_to_copy.each do |app_file|
        m.file app_file, app_file
      end

    end
  end
end