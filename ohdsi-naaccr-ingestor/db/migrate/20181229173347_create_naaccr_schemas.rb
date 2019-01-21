class CreateNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_schemas do |t|
      t.string        :title,                         null: true
      t.string        :schema_type,                   null: true
      t.timestamps
    end
  end
end
