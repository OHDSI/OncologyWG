class AddNaaccrStagingAlgorithmIdToNaaccrSchemas < ActiveRecord::Migration[5.2]
  def change
    add_column :naaccr_schemas, :naaccr_staging_algorithm_id, :integer
  end
end
