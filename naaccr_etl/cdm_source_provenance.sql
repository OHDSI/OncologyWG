--This is DDL for the NAACCR ETL SQL provenance format.

CREATE TABLE cdm_source_provenance(
  cdm_event_id           BIGINT NOT NULL,
  cdm_field_concept_id   INTEGER NOT NULL,
  record_id              varchar(255) NOT NULL
);
