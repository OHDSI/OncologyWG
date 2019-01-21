class AddCodeMapsToToNaaccrItemCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_item_codes, :code_maps_to, :string
  end
end
