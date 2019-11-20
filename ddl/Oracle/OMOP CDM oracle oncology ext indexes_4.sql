/*
************************
Primary key constraints
*************************
*/

ALTER TABLE episode 
ADD CONSTRAINT xpk_episode PRIMARY KEY (episode_id) ;

ALTER TABLE episode_event 
ADD CONSTRAINT xpk_episode_event 
PRIMARY KEY (episode_id, event_id, episode_event_field_concept_id);

/*
***********************
Indices
*************************
*/
CREATE INDEX idx_concept_numeric_concept_id ON concept_numeric (concept_id ASC);
-------------------------------------------------------------------------------------
