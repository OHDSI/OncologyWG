require './lib/naaccr_etl/setup/setup'
class CreateOmopCdm < ActiveRecord::Migration[6.0]
  def change
    NaaccrEtl::Setup.compile_omop_tables
  end
end