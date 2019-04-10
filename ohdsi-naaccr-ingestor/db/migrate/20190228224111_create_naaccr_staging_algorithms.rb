class CreateNaaccrStagingAlgorithms < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_staging_algorithms do |t|
      t.string  :name,                    null: false
      t.string  :algorithm,               null: false
    end
  end
end
