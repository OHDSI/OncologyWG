require './lib/naaccr_etl/setup/setup'
namespace :setup do
  desc "Load OMOP vocabulary tables"
  task(load_omop_vocabulary_tables: :environment) do |t, args|
  end
end