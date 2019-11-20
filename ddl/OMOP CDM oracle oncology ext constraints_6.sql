/*
*********************
CONCEPT_NUMERIC 
*********************
*/
ALTER TABLE concept_numeric 
ADD CONSTRAINT fpk_concept_numeric_concept 
FOREIGN KEY (concept_id)  REFERENCES concept (concept_id);
ALTER TABLE concept_numeric 

ADD CONSTRAINT fpk_concept_numeric_unit 
FOREIGN KEY (unit_concept_id)  REFERENCES concept (concept_id);

ALTER TABLE concept_numeric 
ADD CONSTRAINT fpk_concept_numeric_operator 
FOREIGN KEY (operator_concept_id)  REFERENCES concept (concept_id);


/************************
EPISODE
************************/
ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_person 
FOREIGN KEY (person_id) REFERENCES person (person_id);

ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_concept 
FOREIGN KEY (episode_concept_id) REFERENCES concept (concept_id);

ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_parent 
FOREIGN KEY (episode_parent_id) REFERENCES episode (episode_id);

ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_object_concept 
FOREIGN KEY (episode_object_concept_id) REFERENCES concept (concept_id);

ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_type_concept 
FOREIGN KEY (episode_type_concept_id)  REFERENCES concept (concept_id);

ALTER TABLE episode 
ADD CONSTRAINT fpk_episode_source_concept 
FOREIGN KEY (episode_source_concept_id) REFERENCES concept (concept_id);

ALTER TABLE episode_event 
ADD CONSTRAINT fpk_episode_event_field_concept 
FOREIGN KEY (episode_event_field_concept_id) REFERENCES concept (concept_id);

ALTER TABLE measurement 
ADD CONSTRAINT fpk_measurement_modifier_of_field_concept 
FOREIGN KEY (modifier_of_field_concept_id) REFERENCES concept (concept_id);
-----------------------------------------------------------------------------------