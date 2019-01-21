class CeateNaaccrItemCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :naaccr_item_codes do |t|
      t.integer       :naaccr_item_id,                null: false
      t.string        :code,                          null: true
      t.string        :code_description,              null: true
      t.string        :code_omop_domain_id,           null: true
      t.string        :code_omop_concept_code,        null: true
      t.text          :code_curation_comments,        null: true
      t.string        :code_standard_concept,         null: true
      t.timestamps
    end
  end
end