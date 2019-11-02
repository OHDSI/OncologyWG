require 'fileutils'
module NaaccrEtl
  module Setup
    def self.compile_omop_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql ddl.txt"`
    end

    def self.compile_omop_oncology_extension_tables
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/OMOP CDM postgresql ddl Oncology Module.txt"`
    end

    def self.compile_naaccr_data_points
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/naaccr_etl_input_format_ddl.sql"`
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
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CDM_patch.sql"`
    end

    def self.compile_omop_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql indexes.txt"`
    end

    def self.compile_omop_oncology_extension_indexes
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/OMOP CDM postgresql pk indexes Oncology Module.txt"`
    end

    def self.compile_omop_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql constraints.txt"`
    end

    def self.compile_omop_oncology_extension_constraints
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/OMOP CDM postgresql constraints Oncology Module.txt"`
    end

    def self.execute_naaccr_etl
      ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/lib/naaccr_etl.sql"`
    end
  end
end
