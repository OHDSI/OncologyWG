module NaaccrEtl
  module SpecSetup
    def self.teardown
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE naaccr_data_points CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE person CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_occurrence CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE measurement CASCADE;')
    end
  end
end