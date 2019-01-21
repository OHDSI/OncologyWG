class AddItemMapsToToNaaccrItems < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_items, :item_maps_to, :string
  end
end
