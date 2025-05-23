/************************

Standardized vocabulary

************************/
--HINT DISTRIBUTE ON RANDOM
CREATE TABLE concept_numeric (
  concept_id          INTEGER       NOT NULL,
  value_as_number     NUMERIC       NULL,
  unit_concept_id     INTEGER       NULL,
  operator_concept_id INTEGER       NULL
);

/************************

Standardized clinical data

************************/

--HINT DISTRIBUTE_ON_KEY(person_id)
CREATE TABLE episode (
	episode_id                  BIGINT      NOT NULL,
	person_id                   BIGINT      NOT NULL,
	episode_concept_id          INTEGER     NOT NULL,
	episode_start_datetime      TIMESTAMP 	NOT NULL,
	episode_end_datetime        TIMESTAMP 	NULL,
	episode_parent_id           BIGINT      NULL,
	episode_number              INTEGER     NULL,
	episode_object_concept_id   INTEGER     NOT NULL,
	episode_type_concept_id     INTEGER     NOT NULL,
	episode_source_value        VARCHAR(50) NULL,
	episode_source_concept_id   INTEGER 	  NULL
);

--HINT DISTRIBUTE ON RANDOM
CREATE TABLE episode_event (
  episode_id                      BIGINT 	NOT NULL,
  event_id 		                    BIGINT 	NOT NULL,
  episode_event_field_concept_id  INTEGER NOT NULL
);

/*
--HINT DISTRIBUTE_ON_KEY(person_id)
CREATE TABLE measurement
(
  measurement_id                BIGINT        NOT NULL ,
  person_id                     BIGINT        NOT NULL ,
  measurement_concept_id        INTEGER       NOT NULL ,
  measurement_date              DATE          NULL ,
  measurement_datetime          TIMESTAMP     NOT NULL ,
  measurement_time              VARCHAR(10)   NULL,
  measurement_type_concept_id    INTEGER       NOT NULL ,
  operator_concept_id           INTEGER       NULL ,
  value_as_number               NUMERIC       NULL ,
  value_as_concept_id           INTEGER       NULL ,
  unit_concept_id               INTEGER       NULL ,
  range_low                     NUMERIC       NULL ,
  range_high                    NUMERIC       NULL ,
  provider_id                   BIGINT        NULL ,
  visit_occurrence_id           BIGINT        NULL ,
  visit_detail_id               BIGINT        NULL ,
  measurement_source_value      VARCHAR(50)   NULL ,
  measurement_source_concept_id  INTEGER       NOT NULL ,
  unit_source_value             VARCHAR(50)    NULL ,
  value_source_value            VARCHAR(50)    NULL,
  modifier_of_event_id          BIGINT         NULL,
  modifier_of_field_concept_id  INTEGER       NULL
)
;
*/
--Need to Correct
-- Measurement ALTER statement.  When you are not starting from scratch.
ALTER TABLE measurement ADD COLUMN modifier_of_event_id BIGINT NULL;
ALTER TABLE measurement ADD COLUMN modifier_of_field_concept_id INTEGER NULL;
