class CreateNaaccrSchemaIcdoCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_schema_icdo_codes do |t|
      t.integer       :naaccr_schema_id,              null: false
      t.string        :icdo_code,                     null: true
      t.timestamps
    end
  end
end