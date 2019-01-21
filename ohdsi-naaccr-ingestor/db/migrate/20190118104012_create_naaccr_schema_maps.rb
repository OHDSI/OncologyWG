class CreateNaaccrSchemaMaps < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_schema_maps do |t|
      t.integer        :naaccr_schema_id,                 null: false
      t.string         :mappable_type,                    null: false
      t.integer        :mappable_id,                      null: false
    end
  end
end
