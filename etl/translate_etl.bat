java -jar SqlRender.jar naaccr_etl_sqlserver.sql naaccr_etl_redshift.sql -translate redshift
java -jar SqlRender.jar naaccr_etl_sqlserver.sql naaccr_etl_oracle.sql -translate oracle
java -jar SqlRender.jar naaccr_etl_sqlserver.sql naaccr_etl_postgres.sql -translate postgresql