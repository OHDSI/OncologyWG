class CreateOmopOncologyExtensionTables < ActiveRecord::Migration[6.0]
  def change
    NaaccrEtl::Setup.compile_omop_oncology_extension_tables
  end
end
