--This is DDL for the NAACCR ETL SQL input format.  The NAACCR ETL SQL assumes you have converted your NAACCR data into this structure.

CREATE TABLE naaccr_data_points(
  person_id                    BIGINT,
  record_id                    varchar(255) NULL,
  naaccr_item_number           varchar(255) NULL,
  naaccr_item_value            varchar(255) NULL,
  histology                    varchar(255) NULL,
  site                         varchar(255) NULL,
  histology_site               varchar(255) NULL,
  schema_concept_id            varchar(255) NULL
);
