--	 Prepare dummy data

/*

CREATE TEMPORARY TABLE NAACCR_data_points (	
person_id   	bigint,
record_id	varchar(255) NULL,
naaccr_item_number	varchar(255) NULL,
naaccr_item_value	varchar(255) NULL,
histology	varchar(255) NULL,
site	varchar(255) NULL,
histology_site	varchar(255) NULL
)
;


-- truncate table NAACCR_data_points

INSERT INTO NAACCR_data_points VALUES (12345, 'ABC123', '1390',	'00',	'8140/3', 'C18.7',	'8140/3-C18.7')
;
INSERT INTO NAACCR_data_points VALUES (12345, 'ABC123', '390',	'20191025',	'8140/3', 'C18.7',	'8140/3-C18.7')
;
INSERT INTO NAACCR_data_points VALUES (456789, 'EFG456', '1390', '86',	'8140/3', 'C61.9',	'8140/3-C61.9')
;
INSERT INTO NAACCR_data_points VALUES (456789, 'EFG456', '1400', '82',	'8140/3', 'C61.9',	'8140/3-C61.9')
;
INSERT INTO NAACCR_data_points VALUES (456789, 'EFG456', '390', '20190926',	'8140/3', 'C61.9',	'8140/3-C61.9')
;

select * from NAACCR_data_points order by 1, 2, 3


CREATE TEMPORARY TABLE episode  (
  episode_id                  BIGINT        NOT NULL,
  person_id 				  BIGINT        NOT NULL,
  episode_concept_id          INT       	NOT NULL,
  episode_start_datetime      TIMESTAMP     NULL,       
  episode_end_datetime        TIMESTAMP     NULL,
  episode_parent_id           BIGINT        NULL,
  episode_number              INTEGER       NULL,
  episode_object_concept_id   INTEGER       NOT NULL,
  episode_type_concept_id     INTEGER       NOT NULL,
  episode_source_value        VARCHAR(50)   NULL,
  episode_source_concept_id   INTEGER       NULL
)
;

-- truncate table episode

INSERT INTO episode VALUES (55556666, 12345, 32528,  '2019-10-25 00:00:00',  NULL, NULL, NULL, 0, 32546, NULL, NULL)
;
INSERT INTO episode VALUES (77778888, 456789, 32528, '2019-09-26 00:00:00',  NULL, NULL, NULL, 0, 32546, NULL, NULL)
;

select	* from episode

*/

--#####		Insert did not happen concepts

DROP TABLE IF EXISTS observation_temp;

CREATE TEMPORARY TABLE observation_temp			-- Version 6.0.0
(
  observation_id                BIGINT       NULL ,
  person_id                     BIGINT       NOT NULL ,
  observation_concept_id        BIGINT       NOT NULL ,
  observation_date              DATE         NULL ,
  observation_datetime          TIMESTAMP    NULL ,
  observation_type_concept_id   BIGINT       NULL ,
  value_as_number               NUMERIC      NULL ,
  value_as_string				VARCHAR(255) NULL,
  value_as_concept_id           BIGINT       NULL ,
  qualifier_concept_id			BIGINT       NULL ,
  unit_concept_id               BIGINT       NULL ,
  provider_id                   BIGINT       NULL ,
  visit_occurrence_id           BIGINT       NULL ,
  visit_detail_id               BIGINT       NULL ,
  observation_source_value      VARCHAR(50)   NULL ,
  observation_source_concept_id  BIGINT       NULL ,
  unit_source_value             VARCHAR(50)  NULL ,
  qualifier_source_value		VARCHAR(255) NULL,
  observation_event_id			BIGINT       NULL ,
  obs_event_field_concept_id	BIGINT       NULL ,
  value_as_datetime				BIGINT       NULL ,
  record_id                     VARCHAR(255) NULL
);


--		select	* from concept where concept_code in ('1390@00', '1390@86', '1400@82')

--SET search_path TO 'full_201908_omop_v5';

--Truncate table observation_temp

INSERT INTO observation_temp				-- Version 6.0.0
(
    observation_id
  , person_id
  , observation_concept_id
  , observation_date
  , observation_datetime
  , observation_type_concept_id
  , value_as_number
  , value_as_string
  , value_as_concept_id
  , unit_concept_id
  , qualifier_concept_id
  , provider_id
  , visit_occurrence_id
  , visit_detail_id
  , observation_source_value
  , observation_source_concept_id
  , unit_source_value
  , qualifier_source_value
  , observation_event_id
  , obs_event_field_concept_id
  , value_as_datetime
  , record_id
)
--SET search_path TO 'full_201908_omop_v5';
SELECT (CASE WHEN  (SELECT MAX(observation_id) FROM observation_temp) IS NULL THEN 0 ELSE  (SELECT MAX(observation_id) FROM observation_temp) END + row_number() over())	 AS observation_id
      , ndp.person_id                                                                                                                                             AS person_id
      , c1.concept_id                                                                                                                                           AS observation_concept_id
      , CASE WHEN length(ndp1.naaccr_item_value) = 8 THEN to_date(ndp1.naaccr_item_value,'YYYYMMDD') ELSE NULL END                                                 AS observation_date
      , CASE WHEN length(ndp1.naaccr_item_value) = 8 THEN to_date(ndp1.naaccr_item_value,'YYYYMMDD') ELSE NULL END                                                 AS observation_datetime
      , 32534                                                                                                                                                   AS observation_type_concept_id 
      , NULL																							                                                        AS value_as_number
      , NULL		                                                                                                                                            AS value_as_concept_id
	  , NULL																																					AS value_as_string
      , NULL																			                                                                        AS unit_concept_id
	  , NULL																																					AS qualifier_concept_id
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , d.concept_code                                                                                                                                          AS observation_source_value
      , d.concept_id                                                                                                                                            AS observation_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , NULL		                                                                                                                                            AS qualifier_source_value
      , ep.episode_id 						                                                                                                                    AS observation_event_id
      , 0 			/* Need Vocabulary team to create this! */				      								                                           		AS obs_event_field_concept_id 
	  , NULL																																					AS value_as_datetime
      , ndp.record_id                                                                                                                                           AS record_id
FROM naaccr_data_points AS ndp INNER JOIN concept d                             ON d.vocabulary_id = 'NAACCR' AND d.concept_code = ndp.naaccr_item_number ||  '@' || ndp.naaccr_item_value
                             INNER JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to'
                             INNER JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id 
							 AND c1.vocabulary_id = 'NAACCR' AND c1.concept_class_id = 'NAACCR Value' AND c1.domain_id = 'Observation' AND c1.standard_concept = 'S'
							 INNER JOIN naaccr_data_points ndp1 on ndp.record_id = ndp1.record_id AND ndp1.naaccr_item_number = '390'
							 -- Get epsode_id as observation_event_id
							 INNER JOIN episode ep ON ndp1.person_id = ep.person_id 
 							 AND to_date(ndp1.naaccr_item_value,'YYYYMMDD') = ep.episode_start_datetime 
 							 AND ep.episode_concept_id = 32528			-- Disease First Occurrence
WHERE ndp.person_id IS NOT NULL
AND ndp.naaccr_item_value IS NOT NULL
AND TRIM(ndp.naaccr_item_value) != ''


--SELECT * FROM observation_temp


--#####		Insert data value into observation table
/*

DROP TABLE IF EXISTS observation;

CREATE TEMPORARY TABLE observation		
(
  observation_id                BIGINT       NOT NULL ,
  person_id                     BIGINT       NOT NULL ,
  observation_concept_id        BIGINT       NOT NULL ,
  observation_date              DATE         NOT NULL ,
  observation_datetime          TIMESTAMP    NULL ,
  observation_type_concept_id   BIGINT       NOT NULL ,
  value_as_number               NUMERIC      NULL ,
  value_as_string				VARCHAR(255) NULL,
  value_as_concept_id           BIGINT       NULL ,
  qualifier_concept_id			BIGINT       NULL ,
  unit_concept_id               BIGINT       NULL ,
  provider_id                   BIGINT       NULL ,
  visit_occurrence_id           BIGINT       NULL ,
  visit_detail_id               BIGINT       NULL ,
  observation_source_value      VARCHAR(50)   NULL ,
  observation_source_concept_id  BIGINT       NULL ,
  unit_source_value             VARCHAR(50)  NULL ,
  qualifier_source_value		VARCHAR(255) NULL ,
  observation_event_id			BIGINT       NULL ,
  obs_event_field_concept_id	BIGINT       NULL ,
  value_as_datetime				BIGINT       NULL 
);

*/

INSERT INTO observation
(
    observation_id
  , person_id
  , observation_concept_id
  , observation_date
  , observation_datetime
  , observation_type_concept_id
--  , operator_concept_id
  , value_as_number
  , value_as_string
  , value_as_concept_id
  , qualifier_concept_id
  , unit_concept_id
  , provider_id
  , visit_occurrence_id
  , visit_detail_id
  , observation_source_value
  , observation_source_concept_id
  , unit_source_value
  , qualifier_source_value
  , observation_event_id
  , obs_event_field_concept_id
  , value_as_datetime
)
SELECT 
    observation_id
  , person_id
  , observation_concept_id
  , observation_date
  , observation_datetime
  , observation_type_concept_id
  , value_as_number
  , value_as_string
  , value_as_concept_id
  , qualifier_concept_id
  , unit_concept_id
  , provider_id
  , visit_occurrence_id
  , visit_detail_id
  , observation_source_value
  , observation_source_concept_id
  , unit_source_value
  , qualifier_source_value
  , observation_event_id
  , obs_event_field_concept_id			
  , value_as_datetime
FROM  observation_temp 
 ;
  
-- SELECT * FROM observation
  




 
