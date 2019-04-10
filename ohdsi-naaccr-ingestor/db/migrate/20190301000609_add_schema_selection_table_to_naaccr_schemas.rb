class AddSchemaSelectionTableToNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schemas, :schema_selection_table, :string
  end
end
