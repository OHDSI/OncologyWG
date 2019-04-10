class AddIcdoTypeToNaaccrSchemaIcdoCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schema_icdo_codes, :icdo_type, :string, default: false
  end
end
