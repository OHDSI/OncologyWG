class AddTreatmentTypeToNaaccrItems < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_items, :treatment_type, :string
  end
end
