# RAILS_ENV=test bundle exec rake db:migrate
# RAILS_ENV=test bundle exec rake setup:load_omop_vocabulary_tables
# RAILS_ENV=test bundle exec rake setup:compile_omop_indexes
# RAILS_ENV=test bundle exec rake setup:compile_omop_oncology_extension_indexes
# RAILS_ENV=test bundle exec rake setup:compile_omop_constraints
# RAILS_ENV=test bundle exec rake setup:compile_omop_oncology_extension_constraints

require './lib/naaccr_etl/setup/setup'
namespace :setup do
  desc "Load OMOP vocabulary tables"
  task(load_omop_vocabulary_tables: :environment) do |t, args|
    NaaccrEtl::Setup.load_omop_vocabulary_tables
  end

  desc "Compile OMOP indexes"
  task(compile_omop_indexes: :environment) do  |t, args|
    NaaccrEtl::Setup.compile_omop_indexes
  end

  desc "Compile OMOP Oncology Extension indexes"
  task(compile_omop_oncology_extension_indexes: :environment) do  |t, args|
    NaaccrEtl::Setup.compile_omop_oncology_extension_indexes
  end

  desc "Compile OMOP constraints"
  task(compile_omop_constraints: :environment) do  |t, args|
    NaaccrEtl::Setup.compile_omop_constraints
  end

  desc "Compile OMOP Oncology Extension constraints"
  task(compile_omop_oncology_extension_constraints: :environment) do  |t, args|
    NaaccrEtl::Setup.compile_omop_oncology_extension_constraints
  end
end