class CreateNaaccrVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_versions do |t|
      t.string  :version,                 null: true
    end
  end
end
