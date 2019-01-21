class CeateNaaccrItems < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_items do |t|
      t.string  :item_number,                   null: true
      t.string  :item_name,                     null: true
      t.string  :section,                       null: true
      t.string  :note,                          null: true
      t.string  :item_omop_domain_id,           null: true
      t.string  :item_omop_concept_code,        null: true
      t.text    :item_curation_comments,        null: true
      t.string  :item_standard_concept,         null: true
      t.string  :site_specific_status,          null: true
      t.timestamps
    end
  end
end