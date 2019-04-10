class AddIcdoProcessedToNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schemas, :icdo_processed, :boolean, default: false
  end
end
