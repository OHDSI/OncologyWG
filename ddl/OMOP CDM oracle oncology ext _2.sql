/*********************************************************************************
# Copyright 2019 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/
/************************

Standardized vocabulary

************************/
DROP TABLE concept_numeric;

CREATE TABLE concept_numeric (
  concept_id          NUMBER(10)       NOT NULL,
  value_as_number     FLOAT            NULL,
  unit_concept_id     NUMBER(10)       NULL,
  operator_concept_id NUMBER(10)       NULL
);

/************************

Standardized clinical data

************************/
DROP TABLE episode;

CREATE TABLE episode (
	episode_id                  NUMBER(19)      NOT NULL,
	person_id                   NUMBER(19)      NOT NULL,
	episode_concept_id          NUMBER(10)      NOT NULL,
	episode_start_datetime      TIMESTAMP       NOT NULL,
	episode_end_datetime        TIMESTAMP 	    NULL,
	episode_parent_id           NUMBER(19)      NULL,
	episode_number              NUMBER(10)     	NULL,
	episode_object_concept_id   NUMBER(10)    	NOT NULL,
	episode_type_concept_id     NUMBER(10)    	NOT NULL,
	episode_source_value        VARCHAR(50) 	NULL,
	episode_source_concept_id   NUMBER(10) 	  	NULL
);

DROP TABLE episode_event;

CREATE TABLE episode_event (
  episode_id                      NUMBER(19) 	NOT NULL,
  event_id 		                  NUMBER(19) 	NOT NULL,
  episode_event_field_concept_id  NUMBER(10) 	NOT NULL
);

/*
DROP TABLE measurement;

CREATE TABLE measurement
(
  measurement_id                NUMBER(19)     NOT NULL ,
  person_id                     NUMBER(19)     NOT NULL ,
  measurement_concept_id        NUMBER(10)     NOT NULL ,
  measurement_date              DATE           NULL ,
  measurement_datetime          TIMESTAMP      NOT NULL ,
  measurement_time              VARCHAR(10)    NULL,
  measurement_type_concept_id	NUMBER(10)     NOT NULL ,
  operator_concept_id           NUMBER(10)     NULL ,
  value_as_number               FLOAT          NULL,
  value_as_concept_id           NUMBER(10)     NULL ,
  unit_concept_id               NUMBER(10)     NULL ,
  range_low                     FLOAT          NULL,
  range_high                    FLOAT          NULL,
  provider_id                   NUMBER(19)     NULL ,
  visit_occurrence_id           NUMBER(19)     NULL ,
  visit_detail_id               NUMBER(19) 	   NULL ,
  measurement_source_value		VARCHAR(50)	   NULL ,
  measurement_source_concept_id	NUMBER(10)     NOT NULL ,
  unit_source_value             VARCHAR(50)	   NULL ,
  value_source_value            VARCHAR(50)	   NULL,
  modifier_of_event_id          NUMBER(19)     NULL,
  modifier_of_field_concept_id 	NUMBER(10)     NULL
);
*/
-- Measurement ALTER statement.  When you are not starting from scratch.
ALTER TABLE measurement ADD (modifier_of_event_id NUMBER(19) NULL, modifier_of_field_concept_id NUMBER(10) NULL);


--------------------------------------------------------------------------------------------------------------------------------