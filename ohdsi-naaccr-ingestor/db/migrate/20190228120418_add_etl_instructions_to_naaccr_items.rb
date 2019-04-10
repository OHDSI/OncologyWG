class AddEtlInstructionsToNaaccrItems < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_items, :etl_instructions, :string
  end
end
