# README

This repository is for developing and testing the OMOP NAACCR ETL SQL.

The repository is Ruby on Rails application but the OMOP NAACCR ETL SQL is pure SQL and the Ruby on Rails repository is used just to setup a test harness.

The OMOP NAACCR SQL lives here: [/etl/naaccr_etl.sql](../naaccr_etl_sqlserver.sql).

To run the test suite locally, do the following:

* Install Ruby 2.6.5.
  * MAC: https://rvm.io/rvm/install
  * Windows: https://rubyinstaller.org/

* Install PostgreSQL.
  * https://www.postgresql.org/download/

* Create databases.
  * CREATE DATABASE naaccr_etl_development;
    CREATE USER naaccr_etl_development WITH CREATEDB PASSWORD 'naaccr_etl_development';
    ALTER DATABASE naaccr_etl_development OWNER TO naaccr_etl_development;
    ALTER USER naaccr_etl_development SUPERUSER;

    CREATE DATABASE naaccr_etl_test;
    CREATE USER naaccr_etl_test WITH CREATEDB PASSWORD 'naaccr_etl_test';
    ALTER DATABASE naaccr_etl_test OWNER TO naaccr_etl_test;
    ALTER USER naaccr_etl_test SUPERUSER;

* Put the path to the psql exectuable within your search path.
  * Mac/Linux
    * Add the following line to your '~/.bash_profile file' `export PATH="/Library/PostgreSQL/10/bin:$PATH"` (Substitute the location/version where PostgreSQL is installed on your computuer)
  * Windows
    * Open Control Panel
    * Click System
    * Click Advanced system settings
    * Click Environment Variables
    * Click the 'PATH' Variable in the 'User variables for' section.
    * Click the 'Edit' button.
    * Append the path to the psql executable to the value preceeded by a semicolon(;).  For example: `;\Program Files\PostgreSQL\10\bin` (Substitute the location/version where PostgreSQL is installed on your computuer)

* Download the latest OMOP vocabulary distribution
  * http://athena.ohdsi.org

* Unzip and prepare the vocabulary to /db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport

* Navigate to the directory containing this Readme file: /etl/naaccr_etl.

* Run `bundle install` to install all dependencies.

* Run the following rake tasks to prepare the testing environment.
  * Mac/Linux
    * OMOP_CDM_VERSION=6.1.0 RAILS_ENV=test bundle exec rake db:migrate
    * OMOP_CDM_VERSION=6.1.0 RAILS_ENV=test bundle exec rake setup:load_omop_vocabulary_tables
    * OMOP_CDM_VERSION=6.1.0 RAILS_ENV=test bundle exec rake setup:compile_omop_indexes
    * RAILS_ENV=test bundle exec rake setup:compile_omop_oncology_extension_indexes
    * OMOP_CDM_VERSION=6.1.0 RAILS_ENV=test bundle exec rake setup:compile_omop_constraints
    * RAILS_ENV=test bundle exec rake setup:compile_omop_oncology_extension_constraints
  * Windows
    * set RAILS_ENV=test
    * bundle exec rake db:migrate
    * bundle exec rake setup:load_omop_vocabulary_tables
    * bundle exec rake setup:compile_omop_indexes
    * bundle exec rake setup:compile_omop_oncology_extension_indexes
    * bundle exec rake setup:compile_omop_constraints
    * bundle exec rake setup:compile_omop_oncology_extension_constraints

* Inspect and write unit test in [/spec/lib/naaccr_etl_spec.rb](spec/lib/naaccr_etl_spec.rb).

* Run `bundle exec rake spec` to run all the unit tests.