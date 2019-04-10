class AddProvenanceToNaaccrItemCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_item_codes, :provenance, :string
  end
end
