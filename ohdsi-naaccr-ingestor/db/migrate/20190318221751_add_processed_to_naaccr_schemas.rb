class AddProcessedToNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schemas, :processed, :boolean, default: false
  end
end
