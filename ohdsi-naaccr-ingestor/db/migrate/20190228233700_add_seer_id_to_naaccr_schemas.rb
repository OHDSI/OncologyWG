class AddSeerIdToNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schemas, :seer_id, :string
  end
end
