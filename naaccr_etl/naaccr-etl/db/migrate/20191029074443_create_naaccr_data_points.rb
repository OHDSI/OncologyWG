require './lib/naaccr_etl/setup/setup'
class CreateNaaccrDataPoints < ActiveRecord::Migration[6.0]
  def change
    NaaccrEtl::Setup.compile_naaccr_data_points
  end
end
