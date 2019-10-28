# README

This repository is for developing and testing the OMOP NAACCR ETL SQL.

The repository is Ruby on Rails application but the OMOP NAACCR ETL SQL is pure SQL and the Ruby on Rails repository is used just to setup a test harness.

The OMOP NAACCR SQL lives here: [lib/naaccr_etl.sql](lib/naaccr_etl.sql).

To run the test suite locally, do the following:

* Install Ruby 2.6.5.
  * MAC: https://rvm.io/rvm/install
  * Windows: https://rubyinstaller.org/

* Install PosgreSQL.
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
* Download the latest OMOP vocabulary distribution
  * http://athena.ohdsi.org

*