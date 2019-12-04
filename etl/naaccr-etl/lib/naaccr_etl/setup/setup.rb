require 'fileutils'
module NaaccrEtl
  module Setup
    def self.compile_omop_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql ddl.txt"`
    end

    def self.compile_omop_oncology_extension_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      file = Dir.pwd
      file.gsub!('etl/naaccr-etl', '')
      file = "#{file}ddl/PostgreSQL/OMOP CDM postgresql ddl Oncology Module.txt"
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end

    def self.compile_naaccr_data_points
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      file = Dir.pwd
      file.gsub!('naaccr-etl', '')
      file = "#{file}naaccr_etl_input_format_ddl.sql"

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end

    def self.load_omop_vocabulary_tables
      file_name = "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql.template"
      file_name_dest = file_name.gsub('.template','')
      FileUtils.cp(file_name, file_name_dest)
      text = File.read(file_name_dest)
      text = text.gsub(/RAILS_ROOT/, "#{Rails.root}")
      File.open(file_name_dest, "w") {|file| file.puts text }

      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql"`

      file = Dir.pwd
      file.gsub!('etl/naaccr-etl', '')
      file = "#{file}ddl/PostgreSQL/CDM_patch.sql"

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end

    def self.compile_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql indexes.txt"`
    end

    def self.compile_omop_oncology_extension_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      file = Dir.pwd
      file.gsub!('etl/naaccr-etl', '')
      file = "#{file}ddl/PostgreSQL/OMOP CDM postgresql pk indexes Oncology Module.txt"

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end

    def self.compile_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql constraints.txt"`
    end

    def self.compile_omop_oncology_extension_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      file = Dir.pwd
      file.gsub!('etl/naaccr-etl', '')
      file = "#{file}ddl/PostgreSQL/OMOP CDM postgresql constraints Oncology Module.txt"

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end

    def self.execute_naaccr_etl(legacy=false)
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      file = Dir.pwd
      file.gsub!('naaccr-etl', '')

      if legacy
        file = "#{file}naaccr_etl_postgresql_legacy.sql"
      else
        file = "#{file}naaccr_etl_postgresql.sql"
      end

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} -U #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{file}"`
    end
  end
end
