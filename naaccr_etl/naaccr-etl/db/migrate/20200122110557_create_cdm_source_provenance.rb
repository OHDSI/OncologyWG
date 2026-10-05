require './lib/naaccr_etl/setup/setup'
class CreateCdmSourceProvenance < ActiveRecord::Migration[6.0]
  def change
    NaaccrEtl::Setup.compile_cdm_source_provenance
  end
end
