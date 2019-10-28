require 'fileutils'
require 'csv'
module NaaccrEtl
  module Setup
    def self.compile_omop_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql ddl.txt"`
    end

    def self.load_omop_vocabulary_tables
      file_name = "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql.template"
      file_name_dest = file_name.gsub('.template','')
      FileUtils.cp(file_name, file_name_dest)
      text = File.read(file_name_dest)
      text = text.gsub(/RAILS_ROOT/, "#{Rails.root}")
      File.open(file_name_dest, "w") {|file| file.puts text }

      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql"`
    end

    def self.compile_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql constraints.sql"`
    end

    def self.compile_omop_vocabulary_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql indexes standardized vocabulary.sql"`
    end

    def self.drop_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/Drop OMOP CDM postgresql indexes.sql"`
    end

    def self.drop_omop_vocabulary_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/Drop OMOP CDM postgresql indexes standardized vocabulary.sql"`
    end

    def self.compile_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/OMOP CDM postgresql indexes.sql"`
    end

    def self.truncate_omop_vocabulary_tables
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_ancestor CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_class CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_relationship CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_synonym CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE domain CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_strength CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE relationship CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE vocabulary CASCADE;')
    end

    def self.drop_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/DROP OMOP CDM postgresql constraints.sql"`
    end
  end
end

# vocabulary refresh
# bundle exec rake db:migrate
# bundle exec rake data:drop_omop_indexes
# bundle exec rake data:drop_omop_vocabulary_indexes
# bundle exec rake data:truncate_omop_vocabulary_tables
# bundle exec rake data:drop_omop_constraints
# bundle exec rake data:load_omop_vocabulary_tables
# bundle exec rake data:compile_omop_vocabulary_indexes
# bundle exec rake data:compile_omop_constraints
# bundle exec rake data:compile_omop_indexes