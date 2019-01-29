-- Episode
CREATE TABLE episode (
	episode_id 			BIGINT 		NOT NULL,
	person_id 			BIGINT 		NOT NULL,
	episode_start_datetime 		TIMESTAMP 	NOT NULL,
	episode_end_datetime 		TIMESTAMP 	NOT NULL,
	episode_concept_id 		INTEGER 	NOT NULL,
	episode_parent_id 		INTEGER 	NULL,
	episode_number 			INTEGER 	NULL,
	episode_object_concept_id 	INTEGER 	NOT NULL,
	episode_type_concept_id 	INTEGER 	NOT NULL,
	episode_source_value 		VARCHAR(50) 	NULL,
	episode_source_concept_id 	INTEGER 	NULL
)
;

-- Episode_Event
CREATE TABLE episode_event (
	episode_id 		BIGINT 	NOT NULL,
	event_id 		BIGINT 	NOT NULL,
	event_field_concept_id 	INTEGER NOT NULL
)
;

-- Measurement
CREATE TABLE measurement
(
  measurement_id		BIGINT		NOT NULL ,
  person_id			BIGINT		NOT NULL ,
  measurement_concept_id	INTEGER		NOT NULL ,
  measurement_date		DATE		NULL ,
  measurement_datetime		TIMESTAMP	NOT NULL ,
  measurement_time              VARCHAR(10) 	NULL,
  measurement_type_concept_id	INTEGER		NOT NULL ,
  operator_concept_id		INTEGER		NULL ,
  value_as_number		NUMERIC		NULL ,
  value_as_concept_id		INTEGER		NULL ,
  unit_concept_id		INTEGER		NULL ,
  range_low			NUMERIC		NULL ,
  range_high			NUMERIC		NULL ,
  provider_id			BIGINT		NULL ,
  visit_occurrence_id		BIGINT		NULL ,
  visit_detail_id               BIGINT	     	NULL ,
  measurement_source_value	VARCHAR(50)	NULL ,
  measurement_source_concept_id	INTEGER		NOT NULL ,
  unit_source_value		VARCHAR(50)	NULL ,
  value_source_value		VARCHAR(50)	NULL,
  modifier_of_event_id 		BIGINT 		NULL,
  modifier_of_field_concept_id 	INTEGER 	NULL
  )
;

-- Measurement ALTER statement, just in case
ALTER TABLE measurement
ADD COLUMN modifier_of_event_id BIGINT NULL,
ADD COLUMN modifier_of_field_concept_id INTEGER NULL
;

-- Constraints
	ALTER TABLE measurement
    ADD CONSTRAINT modifier_of_field_concept_id_fk FOREIGN KEY (modifier_of_field_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

	ALTER TABLE episode
    ADD CONSTRAINT person_id_fk FOREIGN KEY (person_id)
    REFERENCES person (person_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_concept_id_fk FOREIGN KEY (episode_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

	ALTER TABLE episode
    ADD CONSTRAINT episode_object_concept_id_fk FOREIGN KEY (episode_object_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_parent_id_fk FOREIGN KEY (episode_parent_id)
    REFERENCES episode (episode_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_source_concept_id_fk FOREIGN KEY (episode_source_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_type_concept_id_fk FOREIGN KEY (episode_type_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

	ALTER TABLE episode
    ADD CONSTRAINT person_id_fk FOREIGN KEY (person_id)
    REFERENCES person (person_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

	ALTER TABLE episode_event
    ADD CONSTRAINT episode_event_pk PRIMARY KEY (episode_id, event_id, event_field_concept_id);
	
	ALTER TABLE episode_event
    ADD CONSTRAINT event_field_concept_id_fk FOREIGN KEY (event_field_concept_id)
    REFERENCES concept (concept_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;	
