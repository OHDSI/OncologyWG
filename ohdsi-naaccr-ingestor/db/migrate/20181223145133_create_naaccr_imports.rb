class CreateNaaccrImports < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_imports do |t|
      t.string  :item_number,               null: true
      t.string  :item_name,                 null: true
      t.string  :section,                   null: true
      t.string  :code,                      null: true
      t.text    :code_description,          null: true
      t.string  :note,                      null: true
      t.timestamps
    end
  end
end