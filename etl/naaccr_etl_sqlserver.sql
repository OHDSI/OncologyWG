BEGIN TRANSACTION;

/* Scripts assumes:
	-using Sql Server
	-input data exists on same database in specified format inside of 'naacr_data_points'
	-histology_site is represented in ICDO3 concept_code format
	-the 'person_id' column is already populated


Contents:
	Clear data from previous executions
	Create temporary tables
	Load ambiguous schema discriminator table
		-create table
		-insert
	Data preparation
		-Insert source into temp table
		-Reformat dates
		-Trim outside spaces on naaccr_item_value
		-Assign schema concept/code
			-ambiguous schemas
			-standard schemas
		-Assign variable concept/code
			-schema-independent
			-schema-dependent
		-Assign value concept/code
	Diagnosis
		-condition occurrence
		-condition modifiers
		-diagnosis episode
		-copy condition modifiers as diagnosis episode modifiers
	Treatment
		-populate episode_temp
			-drugs
			-procedures (excluding surgeries)
			-surgeries
		-populate drug_exposure_temp
		-populate procedure_occurrence_temp
		-update episode_event_temp
		-hardcode episode_object_concept_id for drugs to hemonc
		-treatment episode modifiers
	Connect treatment episodes to disease episodes via parent_id
	Insert temp tables into OMOP
		-episode
		-procedure
		-drug_exposure
		-episode_event
		-measurement
	Person table (commented out)
		-insert new
		-update existing
	Cleanup temp tables

*/



--Preliminary mapping/cleanup

DELETE FROM condition_occurrence
WHERE condition_type_concept_id = 32534;

DELETE FROM measurement
WHERE measurement_type_concept_id = 32534;

DELETE FROM drug_exposure
WHERE drug_type_concept_id = 32534;

DELETE FROM procedure_occurrence
WHERE procedure_type_concept_id = 32534;

DELETE FROM episode;

DELETE FROM episode_event;


-- Create temporary tables


IF OBJECT_ID('condition_occurrence_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE condition_occurrence_temp;  

CREATE TABLE condition_occurrence_temp
(
  condition_occurrence_id        BIGINT        NOT NULL ,
  person_id                     BIGINT        NOT NULL ,
  condition_concept_id          BIGINT        NOT NULL ,
  condition_start_date          DATE          NOT NULL ,
  condition_start_datetime      DATETIME     NULL ,
  condition_end_date            DATE          NULL ,
  condition_end_datetime        DATETIME     NULL ,
  condition_type_concept_id     BIGINT        NOT NULL ,
  stop_reason                   VARCHAR(20)    NULL ,
  provider_id                   BIGINT        NULL ,
  visit_occurrence_id           BIGINT        NULL ,
  --1/23/2019 Removing because we are trying to match the EDW's OMOP instance.
  -- visit_detail_id               BIGINT     NULL ,
  condition_source_value        VARCHAR(50)    NULL ,
  condition_source_concept_id   BIGINT        NULL ,
  condition_status_source_value  VARCHAR(50)   NULL ,
  condition_status_concept_id    BIGINT        NULL,
  record_id                     varchar(255)  NULL
);

IF OBJECT_ID('measurement_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE measurement_temp;  

CREATE TABLE measurement_temp
(
  measurement_id                BIGINT       NOT NULL ,
  person_id                     BIGINT       NOT NULL ,
  measurement_concept_id        BIGINT       NOT NULL ,
  measurement_date              DATE         NOT NULL ,
  measurement_time              VARCHAR(10)  NULL ,
  measurement_datetime          DATETIME    NULL ,
  measurement_type_concept_id   BIGINT       NOT NULL ,
  operator_concept_id           BIGINT       NULL ,
  value_as_number               NUMERIC      NULL ,
  value_as_concept_id           BIGINT       NULL ,
  unit_concept_id               BIGINT       NULL ,
  range_low                     NUMERIC      NULL ,
  range_high                    NUMERIC      NULL ,
  provider_id                   BIGINT       NULL ,
  visit_occurrence_id           BIGINT       NULL ,
  visit_detail_id               BIGINT       NULL ,
  measurement_source_value      VARCHAR(50)   NULL ,
  measurement_source_concept_id  BIGINT       NULL ,
  unit_source_value             VARCHAR(50)  NULL ,
  value_source_value            VARCHAR(50)  NULL ,
  modifier_of_event_id          BIGINT       NULL ,
  modifier_of_field_concept_id  BIGINT       NULL,
  record_id                     VARCHAR(255) NULL
);

IF OBJECT_ID('episode_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE episode_temp;  

CREATE TABLE episode_temp (
  episode_id                  BIGINT        NOT NULL,
  person_id                   BIGINT        NOT NULL,
  episode_concept_id          INTEGER       NOT NULL,
  episode_start_datetime      DATETIME     NULL,       --Fix me
  episode_end_datetime        DATETIME     NULL,
  episode_parent_id           BIGINT        NULL,
  episode_number              INTEGER       NULL,
  episode_object_concept_id   INTEGER       NOT NULL,
  episode_type_concept_id     INTEGER       NOT NULL,
  episode_source_value        VARCHAR(50)   NULL,
  episode_source_concept_id   INTEGER       NULL,
  record_id                   VARCHAR(255)  NULL
)
;

IF OBJECT_ID('episode_event_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE episode_event_temp;  

CREATE TABLE episode_event_temp (
  episode_id                      BIGINT   NOT NULL,
  event_id                         BIGINT   NOT NULL,
  episode_event_field_concept_id  INTEGER NOT NULL
);

IF OBJECT_ID('procedure_occurrence_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE procedure_occurrence_temp;  

 CREATE TABLE procedure_occurrence_temp
 (
  procedure_occurrence_id     BIGINT        NOT NULL ,
  person_id                    BIGINT        NOT NULL ,
  procedure_concept_id        BIGINT        NOT NULL ,
  procedure_date              DATE          NOT NULL ,
  procedure_datetime          DATETIME     NULL ,
  procedure_type_concept_id   BIGINT        NOT NULL ,
  modifier_concept_id         BIGINT        NULL ,
  quantity                    BIGINT        NULL ,
  provider_id                 BIGINT        NULL ,
  visit_occurrence_id         BIGINT        NULL ,
  visit_detail_id             BIGINT        NULL ,
  procedure_source_value      VARCHAR(50)    NULL ,
  procedure_source_concept_id  BIGINT        NULL ,
  modifier_source_value       VARCHAR(50)    NULL,
  episode_id                  BIGINT        NOT NULL,
  record_id                   VARCHAR(255)  NULL
 )
 ;

 IF OBJECT_ID('drug_exposure_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE drug_exposure_temp;  

CREATE TABLE drug_exposure_temp
(
  drug_exposure_id              BIGINT        NOT NULL ,
  person_id                     BIGINT        NOT NULL ,
  drug_concept_id               BIGINT        NOT NULL ,
  drug_exposure_start_date      DATE          NOT NULL ,
  drug_exposure_start_datetime  DATETIME      NULL ,
  drug_exposure_end_date        DATE          NULL ,
  drug_exposure_end_datetime    DATETIME      NULL ,
  verbatim_end_date             DATE          NULL ,
  drug_type_concept_id          BIGINT        NOT NULL ,
  stop_reason                   VARCHAR(20)   NULL ,
  refills                       BIGINT        NULL ,
  quantity                      NUMERIC       NULL ,
  days_supply                   BIGINT        NULL ,
  sig                           TEXT          NULL ,
  route_concept_id              BIGINT        NULL ,
  lot_number                    VARCHAR(50)   NULL ,
  provider_id                   BIGINT        NULL ,
  visit_occurrence_id           BIGINT        NULL ,
  visit_detail_id               BIGINT        NULL ,
  drug_source_value             VARCHAR(50)   NULL ,
  drug_source_concept_id        BIGINT        NULL ,
  route_source_value            VARCHAR(50)   NULL ,
  dose_unit_source_value        VARCHAR(50)   NULL,
  record_id                     VARCHAR(255)    NULL
)

 
 -- Create ambiguous schema discriminator mapping tables
 
 IF OBJECT_ID('ambig_schema_discrim', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE ambig_schema_discrim;  

 CREATE TABLE ambig_schema_discrim(
	schema_concept_code varchar(50) NULL,
	schema_concept_id bigint NULL,
	discrim_item_num varchar(50) NULL,
	discrim_item_value varchar(50) NULL
);
 -- Populate table

 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('stomach', 35909803, '2879', '000');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('stomach', 35909803, '2879', '030');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('stomach', 35909803, '2879', '981');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('stomach', 35909803, '2879', '999');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('esophagus_gejunction', 35909724, '2879', '020');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('esophagus_gejunction', 35909724, '2879', '040');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('esophagus_gejunction', 35909724, '2879', '982');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_distal', 35909746, '2879', '040');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_distal', 35909746, '2879', '070');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_perihilar', 35909846, '2879', '010');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_perihilar', 35909846, '2879', '020');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_perihilar', 35909846, '2879', '050');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_perihilar', 35909846, '2879', '060');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('bile_ducts_perihilar', 35909846, '2879', '999');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('cystic_duct', 35909773, '2879', '030');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('lacrimal_gland', 35909735, '2879', '015');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('lacrimal_sac', 35909739, '2879', '025');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('melanoma_ciliary_body', 35909820, '2879', '010');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('melanoma_iris', 35909687, '2879', '020');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('nasopharynx', 35909813, '2879', '010');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('nasopharynx', 35909813, '2879', '981');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('pharyngeal_tonsil', 35909780, '2879', '020');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum', 35909796, '220', '1');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum', 35909796, '220', '3');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum', 35909796, '220', '4');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum', 35909796, '220', '5');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum', 35909796, '220', '9');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum_female_gen', 35909817, '220', '2');
 INSERT INTO ambig_schema_discrim (schema_concept_code, schema_concept_id, discrim_item_num, discrim_item_value) VALUES ('peritoneum_female_gen', 35909817, '220', '6');



IF OBJECT_ID('naaccr_data_points_tmp', 'U') IS NOT NULL           -- Drop temp table if it exists
  DROP TABLE naaccr_data_points_tmp;  

CREATE TABLE naaccr_data_points_tmp
(
	person_id BIGINT NOT NULL,
	record_id VARCHAR(255) NULL,
	histology_site VARCHAR(255) NULL,
	naaccr_item_number VARCHAR(255) NULL,
	naaccr_item_value VARCHAR(max) NULL,
	schema_concept_id BIGINT NULL,
	schema_concept_code VARCHAR(255),
	variable_concept_id BIGINT NULL,
	variable_concept_code VARCHAR(255) NULL,
	value_concept_id BIGINT NULL,
	value_concept_code VARCHAR(max) NULL,
	type_concept_id BIGINT NULL,
)
;



-- DATA PREP


	 -- Initial data insert
	 INSERT INTO naaccr_data_points_tmp
	 SELECT  person_id
         , record_id
         , histology_site
         , naaccr_item_number
         , naaccr_item_value
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
	 FROM naaccr_data_points
	 WHERE person_id IS NOT NULL;


	-- Format dates
	-- TODO: Replace with item number list
  -- UPDATE naaccr_data_points_tmp
  -- SET naaccr_item_value = TRY_PARSE(SUBSTRING(naaccr_item_value, 1,4) + '-' + SUBSTRING(naaccr_item_value, 5,2)+ '-' + SUBSTRING(naaccr_item_value, 7,2) as date)
  -- WHERE naaccr_item_name like '%date%'
  -- AND naaccr_item_name NOT LIKE '%flag%'
  -- ;


  UPDATE naaccr_data_points_tmp
  SET naaccr_item_value = NULL
  WHERE naaccr_item_number IN(-- todo: verify this list
     '390'
  , '1200'
  , '1210'
  , '1220'
  , '1230'
  , '1240'
  ,'3220'
  )
  AND (
    LEN(naaccr_item_value) != 8
	or
	SUBSTRING(naaccr_item_value, 1,4) NOT BETWEEN '1800' AND '2099' -- year
	or
	SUBSTRING(naaccr_item_value, 5,2) NOT BETWEEN '1' AND '12' -- mo
	or 
	SUBSTRING(naaccr_item_value, 7,2) NOT BETWEEN '1' AND '31' -- day
  );


	-- Trim values just in case leading or trailing spaces
	UPDATE naaccr_data_points_tmp
	SET naaccr_item_value = LTRIM(RTRIM(naaccr_item_value))
	;

   -- Start with ambiguous schemas
    UPDATE naaccr_data_points_tmp
    SET schema_concept_id = schm.schema_concept_id,
      schema_concept_code = schm.schema_concept_code
    FROM 
    (
      SELECT DISTINCT record_id rec_id, asd.schema_concept_id, asd.schema_concept_code
      FROM
      (
        SELECT DISTINCT
              record_id
              ,  histology_site
              , naaccr_item_number
              , naaccr_item_value
        FROM naaccr_data_points_tmp
        WHERE schema_concept_id IS NULL
        --AND naaccr_item_number in (SELECT DISTINCT discrim_item_num FROM .ambig_schema_discrim)
        AND naaccr_item_number in ('220', '2879')
      ) x
      INNER JOIN
      (
      SELECT DISTINCT conc.concept_code, cr.concept_id_2
      FROM concept conc
      INNER JOIN concept_relationship cr
      ON conc. vocabulary_id = 'ICDO3'
      AND cr.concept_id_1 = conc.concept_id
      AND relationship_id = 'ICDO to Schema'
      -- Theres a ton of duplicated schemas here that arent in the mapping file... Item/value must be identical between schemas?
      AND cr.concept_id_2 IN (SELECT DISTINCT schema_concept_id FROM ambig_schema_discrim)
      ) ambig_cond
      ON x.histology_site = ambig_cond.concept_code
      INNER JOIN ambig_schema_discrim asd
      ON ambig_cond.concept_id_2 = asd.schema_concept_id
      AND x.naaccr_item_number = asd.discrim_item_num
      AND x.naaccr_item_value = asd.discrim_item_value
    ) schm
    WHERE record_id = schm.rec_id;

  /**
     MERGE naaccr_data_points_tmp ndp
    USING
    (
      SELECT DISTINCT record_id, asd.schema_concept_id, asd.schema_concept_code
      FROM
      (
        SELECT DISTINCT
              record_id
              ,  histology_site
              , naaccr_item_number
              , naaccr_item_value
        FROM naaccr_data_points_tmp
        WHERE schema_concept_id IS NULL
        --AND naaccr_item_number in (SELECT DISTINCT discrim_item_num FROM .ambig_schema_discrim)
        AND naaccr_item_number in ('220', '2879')
      ) x
      INNER JOIN
      (
      SELECT DISTINCT conc.concept_code, cr.concept_id_2
      FROM concept conc
      INNER JOIN concept_relationship cr
      ON conc. vocabulary_id = 'ICDO3'
      AND cr.concept_id_1 = conc.concept_id
      AND relationship_id = 'ICDO to Schema'
      -- Theres a ton of duplicated schemas here that arent in the mapping file... Item/value must be identical between schemas?
      AND cr.concept_id_2 IN (SELECT DISTINCT schema_concept_id FROM ambig_schema_discrim)
      ) ambig_cond
      ON x.histology_site = ambig_cond.concept_code
      INNER JOIN ambig_schema_discrim asd
      ON ambig_cond.concept_id_2 = asd.schema_concept_id
      AND x.naaccr_item_number = asd.discrim_item_num
      AND x.naaccr_item_value = asd.discrim_item_value
    ) schm
    ON ndp.record_id = schm.record_id
    WHEN MATCHED THEN
    UPDATE
      SET ndp.schema_concept_id = schm.schema_concept_id,
       ndp.schema_concept_code = schm.schema_concept_code
    ;
    **/
    -- Append standard schemas - uses histology_site

    -- UPDATE naaccr_data_points_tmp
    -- SET schema_concept_id   = schm.concept_id,
    --     schema_concept_code = schm.concept_code
    -- FROM naaccr_data_points_tmp ndp JOIN concept c1               ON ndp.histology_site = c1.concept_code
    --                                 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema' AND c1.vocabulary_id = 'ICDO3'
    --                                 JOIN concept schm             ON cr1.concept_id_2 = schm.concept_id AND schm.vocabulary_id = 'NAACCR'
    -- WHERE ndp.schema_concept_id IS NULL;

    -- UPDATE naaccr_data_points_tmp
    -- SET schema_concept_id = schm.schema_concept_id,
    -- schema_concept_code = schm.schema_concept_code
    -- FROM naaccr_data_points_tmp ndp
    -- INNER JOIN
    -- (
    -- SELECT DISTINCT x.concept_code
    -- , c2.concept_id schema_concept_id
    -- , c2.concept_code schema_concept_code
    -- FROM
    -- (
    -- SELECT c1.concept_code
    -- , cr.concept_id_2
    -- -- arbitrary selection of schema, assuming they are identical
    -- -- , ROW_NUMBER() OVER (PARTITION BY c1.concept_id ORDER BY cr.concept_id_2) rn
    -- FROM concept c1
    -- INNER JOIN concept_relationship cr
    -- ON c1.vocabulary_id='ICDO3'
    -- AND c1.concept_id = cr.concept_id_1
    -- AND relationship_id = 'ICDO to Schema'
    -- -- Schema isn't listed as ambiguous
    -- -- AND cr.concept_id_2 NOT IN (SELECT DISTINCT schema_concept_id FROM ambig_schema_discrim)
    -- ) x
    -- INNER JOIN concept c2
    -- ON x.concept_id_2 = c2.concept_id
    -- -- WHERE rn = 1
    -- ) schm
    -- ON ndp.histology_site = schm.concept_code
    -- -- ignore if already mapped
    -- WHERE ndp.schema_concept_id IS NULL
    -- AND schm.schema_concept_id IS NOT NULL
    -- AND naaccr_data_points_tmp.record_id = ndp.record_id;

   /**
   MERGE naaccr_data_points_tmp ndp
   USING
   (
		SELECT DISTINCT x.concept_code
					, c2.concept_id schema_concept_id
					, c2.concept_code schema_concept_code
		FROM
		(
			SELECT  c1.concept_code
				, cr.concept_id_2
				-- arbitrary selection of schema, assuming they are identical
				, ROW_NUMBER() OVER (PARTITION BY c1.concept_id ORDER BY cr.concept_id_2) rn
			FROM concept c1
			INNER JOIN concept_relationship cr
			ON c1.vocabulary_id='ICDO3'
			AND c1.concept_id = cr.concept_id_1
			AND relationship_id = 'ICDO to Schema'
			-- Schema isn't listed as ambiguous
			AND cr.concept_id_2 NOT IN (SELECT DISTINCT schema_concept_id FROM ambig_schema_discrim)
		) x
		INNER JOIN concept c2
		ON x.concept_id_2 = c2.concept_id
		WHERE rn = 1
   ) schm
   ON ndp.histology_site = schm.concept_code
   -- ignore if already mapped
   AND ndp.schema_concept_id IS NULL
   WHEN MATCHED
		THEN UPDATE
			set ndp.schema_concept_id = schm.schema_concept_id,
						 ndp.schema_concept_code = schm.schema_concept_code
   ;
   **/
    -- Append standard schemas - uses histology_site
    UPDATE naaccr_data_points_tmp
    SET schema_concept_id   = schm.concept_id,
        schema_concept_code = schm.concept_code
    FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema' AND c1.vocabulary_id = 'ICDO3'
                    JOIN concept schm             ON cr1.concept_id_2 = schm.concept_id AND schm.vocabulary_id = 'NAACCR'
    WHERE naaccr_data_points_tmp.histology_site = c1.concept_code
    AND naaccr_data_points_tmp.schema_concept_id IS NULL;

	-- Variables

  -- schema-independent
  -- UPDATE naaccr_data_points_tmp
  -- SET variable_concept_code = conc.concept_code
  --       ,variable_concept_id = conc.concept_id
  -- FROM naaccr_data_points_tmp ndp
  -- INNER JOIN
  -- (
  --   SELECT concept_id, concept_code
  --   FROM concept
  --   WHERE vocabulary_id = 'NAACCR'
  --   AND concept_class_id = 'NAACCR Variable'
  -- ) conc
  -- ON variable_concept_id IS NULL
  -- AND conc.concept_id IS NOT NULL
  -- AND ndp.naaccr_item_number = conc.concept_code
  -- WHERE naaccr_data_points_tmp.record_id = ndp.record_id
  -- AND naaccr_data_points_tmp.naaccr_item_number = ndp.naaccr_item_number
  -- ;
	/**
	MERGE naaccr_data_points_tmp ndp
	USING
	(
		SELECT concept_id, concept_code
		FROM concept
		WHERE vocabulary_id = 'NAACCR'
		AND concept_class_id = 'NAACCR Variable'
	) conc
	ON ndp.naaccr_item_number = conc.concept_code
	WHEN MATCHED
		THEN UPDATE
			SET ndp.variable_concept_code = conc.concept_code
				,ndp.variable_concept_id = conc.concept_id
	;
	**/

  -- schema-independent
  UPDATE naaccr_data_points_tmp
  SET variable_concept_code = c1.concept_code
    , variable_concept_id   = c1.concept_id
  FROM concept c1
  WHERE c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Variable'
  AND naaccr_data_points_tmp.variable_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND naaccr_data_points_tmp.naaccr_item_number = c1.concept_code;

  --   schema dependent
  -- UPDATE naaccr_data_points_tmp
  -- SET variable_concept_code = conc.concept_code
  --       ,variable_concept_id = conc.concept_id
  -- FROM naaccr_data_points_tmp ndp
  -- INNER JOIN
  -- (
  --   SELECT concept_id, concept_code
  --   FROM concept
  --   WHERE vocabulary_id = 'NAACCR'
  --   AND concept_class_id = 'NAACCR Variable'
  -- ) conc
  -- ON ndp.variable_concept_id IS NULL
  -- AND conc.concept_id IS NOT NULL
  -- AND CONCAT(ndp.schema_concept_code,'@', ndp.naaccr_item_number) = conc.concept_code
  -- WHERE naaccr_data_points_tmp.record_id = ndp.record_id
  -- AND naaccr_data_points_tmp.naaccr_item_number = ndp.naaccr_item_number
  -- ;
  --   schema dependent
  UPDATE naaccr_data_points_tmp
  SET variable_concept_code = c1.concept_code
    , variable_concept_id   = c1.concept_id
  FROM concept c1
  WHERE c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Variable'
  AND naaccr_data_points_tmp.variable_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND CONCAT(naaccr_data_points_tmp.schema_concept_code,'@', naaccr_data_points_tmp.naaccr_item_number) = c1.concept_code;

  -- -- Values
  -- UPDATE naaccr_data_points_tmp
  -- SET value_concept_code = conc.concept_code
  --     ,value_concept_id = conc.concept_id
  -- FROM naaccr_data_points_tmp ndp
  -- INNER JOIN
  -- (
  --   SELECT concept_id, concept_code
  --   FROM concept
  --   WHERE vocabulary_id = 'NAACCR'
  --   AND concept_class_id = 'NAACCR Value'
  -- ) conc
  -- ON ndp.value_concept_id IS NULL
  -- AND conc.concept_id IS NOT NULL
  -- -- placeholder for better approach
  -- AND LEN(ndp.naaccr_item_value) < 10
  -- AND CONCAT(ndp.variable_concept_code,'@', ndp.naaccr_item_value) = conc.concept_code
  -- WHERE naaccr_data_points_tmp.record_id = ndp.record_id
  -- AND naaccr_data_points_tmp.naaccr_item_number = ndp.naaccr_item_number
  -- ;
  -- Values
  UPDATE naaccr_data_points_tmp
  SET   value_concept_code = c1.concept_code
      , value_concept_id   = c1.concept_id
  FROM concept c1
  WHERE naaccr_data_points_tmp.value_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Value'
  AND LEN(naaccr_data_points_tmp.naaccr_item_value) < 10
  AND CONCAT(naaccr_data_points_tmp.variable_concept_code,'@', naaccr_data_points_tmp.naaccr_item_value) = c1.concept_code;

  -- Type
  -- UPDATE naaccr_data_points_tmp
  -- SET type_concept_id = cr.concept_id_2
  -- FROM naaccr_data_points_tmp ndp
  -- INNER JOIN
  -- (
  --   SELECT *
  --   FROM concept_relationship
  --   WHERE relationship_id = 'Has type'
  -- ) cr
  -- ON ndp.variable_concept_id = cr.concept_id_1
  -- WHERE naaccr_data_points_tmp.record_id = ndp.record_id
  -- AND naaccr_data_points_tmp.naaccr_item_number = ndp.naaccr_item_number
  -- ;
  -- Type
  UPDATE naaccr_data_points_tmp
  SET type_concept_id = cr1.concept_id_2
  FROM concept_relationship cr1
  WHERE cr1.relationship_id = 'Has type'
  AND naaccr_data_points_tmp.variable_concept_id = cr1.concept_id_1;







--- DIAGNOSIS



  -- Condition Occurrence


  INSERT INTO condition_occurrence_temp
  (
    condition_occurrence_id
    , person_id
    , condition_concept_id
    , condition_start_date
    , condition_start_datetime
    , condition_end_date
    , condition_end_datetime
    , condition_type_concept_id
    , stop_reason
    , provider_id
    , visit_occurrence_id
  --, visit_detail_id
    , condition_source_value
    , condition_source_concept_id
    , condition_status_source_value
    , condition_status_concept_id
    , record_id
  )

  SELECT ( CASE WHEN  (SELECT MAX(condition_occurrence_id) FROM condition_occurrence) IS NULL
            THEN 0
            ELSE  (SELECT MAX(condition_occurrence_id) FROM condition_occurrence)
          END + row_number() over (order by s.record_id)
      ) AS condition_occurrence_id
      , s.person_id                                                                                           AS person_id
      , c2.concept_id                                                                                         AS condition_concept_id
      , CONVERT(date, s.naaccr_item_value,112)  		                                                          AS condition_start_date
      , CONVERT(date, s.naaccr_item_value,112)																	  AS condition_start_datetime
      , NULL                                                                                                  AS condition_end_date
      , NULL                                                                                                  AS condition_end_datetime
      , 32534                                                                                                 AS condition_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                  AS stop_reason
      , NULL                                                                                                  AS provider_id
      , NULL                                                                                                  AS visit_occurrence_id
  --    , NULL                                                                                                  AS visit_detail_id
      , s.histology_site                                                                                      AS condition_source_value
      , d.concept_id                                                                                          AS condition_source_concept_id
      , NULL                                                                                                  AS condition_status_source_value
      , NULL                                                                                                  AS condition_status_concept_id
      , s.record_id                                                                                           AS record_id
  FROM

    (
      SELECT *
      FROM naaccr_data_points
      WHERE naaccr_item_number = '390'  -- Date of diag
      AND naaccr_item_value IS NOT NULL
      AND person_id IS NOT NULL
    ) s
      JOIN concept d
        ON d.vocabulary_id = 'ICDO3'
        AND d.concept_code = s.histology_site
      JOIN concept_relationship    ra
        ON ra.concept_id_1 = d.concept_id
        AND ra.relationship_id = 'Maps to'
      JOIN concept  c2
        ON c2.standard_concept = 'S'
        AND ra.concept_id_2 = c2.concept_id
        AND c2.domain_id = 'Condition'
    ;

  -- assumes there is no IDENTITY on condition_occurrence_id
  INSERT INTO condition_occurrence
  (
    condition_occurrence_id
    , person_id
    , condition_concept_id
    , condition_start_date
    , condition_start_datetime
    , condition_end_date
    , condition_end_datetime
    , condition_type_concept_id
    , stop_reason
    , provider_id
    , visit_occurrence_id
  --, visit_detail_id
    , condition_source_value
    , condition_source_concept_id
    , condition_status_source_value
    , condition_status_concept_id
  )
  SELECT  condition_occurrence_id
      , person_id
      , condition_concept_id
      , condition_start_date
      , condition_start_datetime
      , condition_end_date
      , condition_end_datetime
      , condition_type_concept_id
      , record_id
      , provider_id
      , visit_occurrence_id
      --, visit_detail_id
      , condition_source_value
      , condition_source_concept_id
      , condition_status_source_value
      , condition_status_concept_id
  FROM condition_occurrence_temp
  ;



  --   condition modifiers

    INSERT INTO measurement_temp
    (
      measurement_id
      , person_id
      , measurement_concept_id
      , measurement_date
      , measurement_time
      , measurement_datetime
      , measurement_type_concept_id
      , operator_concept_id
      , value_as_number
      , value_as_concept_id
      , unit_concept_id
      , range_low
      , range_high
      , provider_id
      , visit_occurrence_id
      , visit_detail_id
      , measurement_source_value
      , measurement_source_concept_id
      , unit_source_value
      , value_source_value
      , modifier_of_event_id
      , modifier_of_field_concept_id
      , record_id
    )


    SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement) IS NULL
        THEN 0
        ELSE  (SELECT MAX(measurement_id) FROM measurement)
      END + row_number() over (order by ndp.record_id)) AS measurement_id
        , ndp.person_id                                                                                                                                             AS person_id
        , conc.concept_id                                                                                                                                        AS measurement_concept_id
        , cot.condition_start_date                                                                                                                                AS measurement_date
        , NULL                                                                                                                                                    AS measurement_time
        , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
        , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
        , conc_num.operator_concept_id                                                                                                                            AS operator_concept_id
        , CASE
        WHEN ndp.value_concept_id IS NULL
            AND ndp.type_concept_id = 32676
  --          AND ISNUMERIC(ndp.naaccr_item_value) = 1 MGURLEY There is no ISNUMERIC on PostgreSQL
          THEN COALESCE(CAST(ndp.naaccr_item_value AS float), conc_num.value_as_number)
        ELSE NULL
      END as value_as_number
        , ndp.value_concept_id                                                                                                                          AS value_as_concept_id
        , COALESCE(unit_cr.concept_id_2, conc_num.unit_concept_id)                                                                                                  AS unit_concept_id
        , NULL                                                                                                                                                    AS range_low
        , NULL                                                                                                                                                    AS range_high
        , NULL                                                                                                                                                    AS provider_id
        , NULL                                                                                                                                                    AS visit_occurrence_id
        , NULL                                                                                                                                                    AS visit_detail_id
        , ndp.variable_concept_code                                                                                                                                         AS measurement_source_value
        , ndp.variable_concept_id                                                                                                                                         AS measurement_source_concept_id
        , NULL                                                                                                                                                    AS unit_source_value
        , naaccr_item_value                                                                                                                                         AS value_source_value
        , cot.condition_occurrence_id                                                                                                                             AS modifier_of_event_id
        , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
        , ndp.record_id                                                                                                                                             AS record_id
    FROM
    (
      SELECT *
      FROM naaccr_data_points_tmp
      WHERE person_id IS NOT NULL
      -- concept is modifier of a diagnosis item (child of site/hist)
      /**
      AND variable_concept_id IN ( SELECT DISTINCT concept_id_1
                       FROM concept_relationship
                       WHERE relationship_id = 'Has parent item'
                       AND concept_id_2 in (35918588 -- primary site
                                  ,35918916 -- histology
                                  )
                       GROUP BY concept_id_1
                       HAVING COUNT(DISTINCT concept_id_2) > 1
                      )
                      **/
      AND variable_concept_id IN (  SELECT DISTINCT concept_id_1
                      FROM concept_relationship
                      WHERE relationship_id = 'Has parent item'
                      AND concept_id_2 in (35918588 -- primary site
                                ,35918916 -- histology
                                )
                      )
      -- filter empty values
      AND LEN(naaccr_item_value) > 0

     ) ndp

     -- Get condition_occurrence record
      INNER JOIN condition_occurrence_temp cot
      ON ndp.record_id = cot.record_id

    -- Get standard concept
    INNER JOIN concept_relationship cr
      on ndp.variable_concept_id = cr.concept_id_1
      and cr.relationship_id = 'Maps to'
    INNER JOIN concept conc
      on cr.concept_id_2 = conc.concept_id
      AND conc.domain_id = 'Measurement'
      -- AND standard_concept = 'S'    -- Should we add this now or wait?

    -- Get Unit
    LEFT OUTER JOIN concept_relationship unit_cr
      ON ndp.variable_concept_id = unit_cr.concept_id_1
      and unit_cr.relationship_id = 'Has unit'

    -- Get numeric value
    LEFT OUTER JOIN concept_numeric conc_num
      ON ndp.type_concept_id = 32676 --'Numeric'
      AND ndp.value_concept_id = conc_num.concept_id
    ;



  -- Diagnosis episodes



  INSERT INTO episode_temp
  (
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
    , episode_number
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
    , record_id
  )
  SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode) IS NULL THEN 0 ELSE  (SELECT MAX(episode_id) FROM episode) END + row_number() over(order by cot.record_id))                 AS episode_id
      , cot.person_id                                                                                                                                           AS person_id
      , 32528                                                                                                                                                   AS episode_concept_id  --Disease First Occurrence
      , cot.condition_start_datetime                                                                                                                            AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , cot.condition_concept_id                                                                                                                                AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , cot.condition_source_value                                                                                                                              AS episode_source_value
      , cot.condition_source_concept_id                                                                                                                         AS episode_source_concept_id
      , cot.record_id                                                                                                                                           AS record_id
  FROM condition_occurrence_temp cot;


  INSERT INTO episode_event_temp
  (
    episode_id
    , event_id
    , episode_event_field_concept_id

  )
  SELECT  et.episode_id                     AS episode_id
      , cot.condition_occurrence_id       AS event_id
      , 1147127                           AS episode_event_field_concept_id --condition_occurrence.condition_occurrence_id
  FROM condition_occurrence_temp cot
  JOIN episode_temp et
    ON cot.record_id = et.record_id
  ;

  --Step 7: Copy Condition Occurrence Measurements for Disease Episode
  INSERT INTO measurement_temp
  (
    measurement_id
    , person_id
    , measurement_concept_id
    , measurement_date
    , measurement_time
    , measurement_datetime
    , measurement_type_concept_id
    , operator_concept_id
    , value_as_number
    , value_as_concept_id
    , unit_concept_id
    , range_low
    , range_high
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , measurement_source_value
    , measurement_source_concept_id
    , unit_source_value
    , value_source_value
    , modifier_of_event_id
    , modifier_of_field_concept_id
    , record_id
  )
  SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL
  THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over(order by mt.record_id)) AS measurement_id
      , mt.person_id                                                                                                                                                      AS person_id
      , mt.measurement_concept_id                                                                                                                                         AS measurement_concept_id
      , mt.measurement_date                                                                                                                                               AS measurement_date
      , mt.measurement_time                                                                                                                                               AS measurement_time
      , mt.measurement_datetime                                                                                                                                           AS measurement_datetime
      , mt.measurement_type_concept_id                                                                                                                                    AS measurement_type_concept_id
      , mt.operator_concept_id                                                                                                                                            AS operator_concept_id
      , mt.value_as_number                                                                                                                                                AS value_as_number
      , mt.value_as_concept_id                                                                                                                                            AS value_as_concept_id
      , mt.unit_concept_id                                                                                                                                                AS unit_concept_id
      , mt.range_low                                                                                                                                                      AS range_low
      , mt.range_high                                                                                                                                                     AS range_high
      , mt.provider_id                                                                                                                                                    AS provider_id
      , mt.visit_occurrence_id                                                                                                                                            AS visit_occurrence_id
      , mt.visit_detail_id                                                                                                                                                AS visit_detail_id
      , mt.measurement_source_value                                                                                                                                       AS measurement_source_value
      , mt.measurement_source_concept_id                                                                                                                                  AS measurement_source_concept_id
      , mt.unit_source_value                                                                                                                                              AS unit_source_value
      , mt.value_source_value                                                                                                                                             AS value_source_value
      , et.episode_id                                                                                                                                                     AS modifier_of_event_id
      , 1000000003                                                                                                                                                        AS modifier_field_concept_id -- ‘episode.episode_id’ concept
      , mt.record_id                                                                                                                                                     AS record_id
  FROM measurement_temp mt
  JOIN episode_temp et
  ON mt.record_id = et.record_id
  ;
--
--
--
--
--
--
--
--
--
--
--
-- Treatment Episodes

  -- populate episode_temp

  -- insert drugs into episode_temp
  INSERT INTO episode_temp
  (
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
    , episode_number
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
    , record_id

  )
  SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode_temp) IS NULL THEN 0 ELSE
      (SELECT MAX(episode_id) FROM episode_temp) END + row_number() over(order by ndp.record_id))                 AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , 32531 -- Treatment regimen
      , CONVERT(date,ndp_dates.naaccr_item_value, 112)  		                                                          AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , ndp.value_concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , ndp.value_concept_code                                                                                                     AS episode_source_value
      , ndp.variable_concept_id                                                                                                                                           AS episode_source_concept_id
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT *
    FROM naaccr_data_points_tmp
    WHERE naaccr_item_number IN ( '1390', '1400', '1410')
  ) ndp
  INNER JOIN concept_relationship cr
    ON ndp.variable_concept_id = cr.concept_id_1
    AND relationship_id = 'Variable has date'
  INNER JOIN naaccr_data_points_tmp ndp_dates
    ON cr.concept_id_2 = ndp_dates.variable_concept_id
    AND ndp.record_id = ndp_dates.record_id
  -- filter null dates
  WHERE ndp_dates.naaccr_item_value IS NOT NULL
  AND ndp_dates.naaccr_item_value NOT IN('99999999', '0')
  ;
 
  -- insert procedure (all except surgeries)
  INSERT INTO episode_temp
  (
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
    , episode_number
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
    , record_id

  )
  SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode_temp) IS NULL THEN 0 ELSE
      (SELECT MAX(episode_id) FROM episode_temp) END + row_number() over(order by ndp.record_id))                 AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , 32531 -- Treatment regimen
      , CONVERT(date,ndp_dates.naaccr_item_value,112)  		                                                          AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , ndp.value_concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , ndp.variable_concept_code                                                                                                     AS episode_source_value
      , ndp.variable_concept_id
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT *
    FROM naaccr_data_points_tmp
    WHERE naaccr_item_number NOT IN ( '1290' )
  ) ndp
  INNER JOIN concept conc
    ON ndp.value_concept_id = conc.concept_id
    AND conc.domain_id = 'Procedure'
  INNER JOIN concept_relationship cr
    ON ndp.variable_concept_id = cr.concept_id_1
    AND relationship_id = 'Variable has date'
  INNER JOIN naaccr_data_points_tmp ndp_dates
    ON cr.concept_id_2 = ndp_dates.variable_concept_id
    AND ndp.record_id = ndp_dates.record_id
  -- filter null dates
  WHERE ndp_dates.naaccr_item_value IS NOT NULL
  ;
 

  -- insert surgery procedures
  -- this requires its own schema mapping (ICDO to Proc Schema)
  INSERT INTO episode_temp
  (
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
    , episode_number
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
    , record_id

  )
  SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode_temp) IS NULL THEN 0 ELSE
      (SELECT MAX(episode_id) FROM episode_temp) END + row_number() over(order by ndp.record_id))                 AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , 32531 -- Treatment regimen
      , CONVERT(date,ndp_dates.naaccr_item_value,112)  		                                                          AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , var_conc.concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , var_conc.concept_code                                                                                                      AS episode_source_value
      , var_conc.concept_id                                                                                                                                           AS episode_source_concept_id
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT *
    FROM naaccr_data_points_tmp
    WHERE naaccr_item_number = '1290'
  ) ndp
  -- get icdo
  INNER JOIN concept conc
    ON vocabulary_id = 'ICDO3'
    AND ndp.histology_site = conc.concept_code
  -- get proc schema
  INNER JOIN concept_relationship cr_schema
    ON conc.concept_id = cr_schema.concept_id_1
    AND cr_schema.relationship_id = 'ICDO to Proc Schema'
  INNER JOIN concept schem_conc
    ON cr_schema.concept_id_2 = schem_conc.concept_id
  -- get procedure
  INNER JOIN concept var_conc
    ON var_conc.concept_class_id = 'NAACCR Procedure'
    AND CONCAT(schem_conc.concept_code, '@1290@', ndp.naaccr_item_value) = var_conc.concept_code

  -- hardcoded for now until update
  INNER JOIN naaccr_data_points_tmp ndp_dates
    ON ndp_dates.naaccr_item_number = '1200'
    AND ndp.record_id = ndp_dates.record_id
  -- filter null dates
  WHERE ndp_dates.naaccr_item_value IS NOT NULL
  ;

  -- Insert from episode_temp into domain temp tables

  -- drug
   INSERT INTO drug_exposure_temp
  (
    drug_exposure_id
    , person_id
    , drug_concept_id
    , drug_exposure_start_date
    , drug_exposure_start_datetime
    , drug_exposure_end_date
    , drug_exposure_end_datetime
    , verbatim_end_date
    , drug_type_concept_id
    , stop_reason
    , refills
    , quantity
    , days_supply
    , sig
    , route_concept_id
    , lot_number
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , drug_source_value
    , drug_source_concept_id
    , route_source_value
    , dose_unit_source_value
    , record_id
  )
  SELECT ( CASE WHEN  (SELECT MAX(drug_exposure_id) FROM drug_exposure)
    IS NULL THEN 0 ELSE  (SELECT MAX(drug_exposure_id) FROM drug_exposure) END + row_number() over(order by et.record_id))                             AS drug_exposure_id
    , et.person_id                                                                                                                                                                                  AS person_id
    , et.episode_object_concept_id                                                                                                                                                                  AS drug_concept_id
    , et.episode_start_datetime                                                                                                                                                               AS drug_exposure_start_date
    , et.episode_start_datetime                                                                                                                                                                     AS drug_exposure_start_datetime
    , et.episode_start_datetime                                                                                                                                                             AS drug_exposure_end_date
    , et.episode_start_datetime                                                                                                                                                                     AS drug_exposure_end_datetime
    , NULL                                                                                                                                                                                          AS verbatim_end_date
    , 32534                                                                                                                                                                                          AS drug_type_concept_id -- ‘Tumor registry’ concept. Fix me.
    , NULL                                                                                                                                                                                          AS stop_reason
    , NULL                                                                                                                                                                                          AS refills
    , NULL                                                                                                                                                                                          AS quantity
    , NULL                                                                                                                                                                                          AS days_supply
    , NULL                                                                                                                                                                                          AS sig
    , NULL                                                                                                                                                                                          AS route_concept_id
    , NULL                                                                                                                                                                                          AS lot_number
    , NULL                                                                                                                                                                                          AS provider_id
    , NULL                                                                                                                                                                                          AS visit_occurrence_id
    , NULL                                                                                                                                                                                          AS visit_detail_id
    , et.episode_source_value                                                                                                                                                                       AS drug_source_value
    , et.episode_source_concept_id                                                                                                                                                                  AS drug_source_concept_id
    , NULL                                                                                                                                                                                          AS route_source_value
    , NULL
    , et.record_id                                                                                                                                                                                          AS dose_unit_source_value
  FROM episode_temp et
  JOIN concept c1
  ON et.episode_object_concept_id = c1.concept_id
  AND c1.standard_concept IS NULL
  AND c1.domain_id = 'Drug';


  -- procedure
  INSERT INTO procedure_occurrence_temp
  (
     procedure_occurrence_id
   , person_id
   , procedure_concept_id
   , procedure_date
   , procedure_datetime
   , procedure_type_concept_id
   , modifier_concept_id
   , quantity
   , provider_id
   , visit_occurrence_id
   , visit_detail_id
   , procedure_source_value
   , procedure_source_concept_id
   , modifier_source_value
   , episode_id
   , record_id
  )
  SELECT ( CASE WHEN  (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence) IS NULL THEN 0
  ELSE  (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence) END + row_number() over(order by et.record_id))  AS procedure_occurrence_id
    , et.person_id                                                                                                                                                                                   AS person_id
    , et.episode_object_concept_id                                                                                                                                                                   AS procedure_concept_id
    , et.episode_start_datetime                                                                                                                                                           AS procedure_date
    , et.episode_start_datetime                                                                                                                                                                      AS procedure_datetime
    , 32534                                                                                                                                                                                          AS procedure_type_concept_id -- ‘Tumor registry’ concept. Fix me.
    , NULL                                                                                                                                                                                           AS modifier_concept_id
    , 1                                                                                                                                                                                              AS quantity --Is this OK to hardcode?
    , NULL                                                                                                                                                                                           AS provider_id
    , NULL                                                                                                                                                                                           AS visit_occurrence_id
    , NULL                                                                                                                                                                                           AS visit_detail_id
    , et.episode_source_value                                                                                                                                                                        AS procedure_source_value
    , et.episode_source_concept_id                                                                                                                                                                   AS procedure_source_concept_id
    , NULL                                                                                                                                                                                           AS modifier_source_value
    , et.episode_id                                                                                                                                                                                  AS episode_id
    , et.record_id                                                                                                                                                                                    AS record_id
    -- , c1.concept_name
  FROM episode_temp et
  JOIN concept c1
    ON et.episode_object_concept_id = c1.concept_id
    AND c1.standard_concept = 'S'
    AND c1.domain_id = 'Procedure';


-- Update episode_event_temp

  -- Connect Drug Exposure to Treatment Episodes in Episode Event
  INSERT INTO episode_event_temp
  (
    episode_id
    , event_id
    , episode_event_field_concept_id

  )
  SELECT  et.episode_id                     AS episode_id
      , det.drug_exposure_id              AS event_id
      , 1147094                           AS episode_event_field_concept_id --drug_exposure.drug_exposure_id
  FROM drug_exposure_temp det JOIN episode_temp et ON det.record_id = et.record_id AND det.drug_concept_id = et.episode_object_concept_id;


  --Connect Procedure Occurrence to Treatment Episodes in Episode Event
  INSERT INTO episode_event_temp
  (
    episode_id
    , event_id
    , episode_event_field_concept_id

  )
  SELECT  et.episode_id                     AS episode_id
      , pet.procedure_occurrence_id       AS event_id
      , 1147082                           AS episode_event_field_concept_id --procedure_occurrence.procedure_occurrence_id
  FROM procedure_occurrence_temp pet
  JOIN episode_temp et
    ON pet.record_id = et.record_id
    AND pet.procedure_concept_id = et.episode_object_concept_id
  ;


  -- Drug Treatment Episodes:   Update to standard 'Regimen' concepts.
  UPDATE episode_temp
  SET episode_object_concept_id = CASE
                    WHEN episode_source_value = '1390@01' THEN 35803401 --Hemonc Chemotherapy Modality
                    WHEN episode_source_value = '1390@02' THEN 35803401
                    WHEN episode_source_value = '1390@03' THEN 35803401
                    WHEN episode_source_value = '1400@01' THEN 35803407
                    WHEN episode_source_value = '1410@01' THEN 35803410
                  ELSE episode_object_concept_id
                  END;

-- Treatment Episode Modifiers

  INSERT INTO measurement_temp
  (
    measurement_id
    , person_id
    , measurement_concept_id
    , measurement_date
    , measurement_time
    , measurement_datetime
    , measurement_type_concept_id
    , operator_concept_id
    , value_as_number
    , value_as_concept_id
    , unit_concept_id
    , range_low
    , range_high
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , measurement_source_value
    , measurement_source_concept_id
    , unit_source_value
    , value_source_value
    , modifier_of_event_id
    , modifier_of_field_concept_id
    , record_id
  )


  SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL
  THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over(order by ndp.record_id)) AS measurement_id
      , ndp.person_id                                                                                                                                             AS person_id
      , conc.concept_id                                                                                                                                        AS measurement_concept_id
      , et.episode_start_datetime                                                                                                                           AS measurement_time
      ,null
    , et.episode_start_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , conc_num.operator_concept_id                                                                                                                            AS operator_concept_id
      , CASE
      WHEN ndp.value_concept_id IS NULL
          AND ndp.type_concept_id = 32676
          --AND ISNUMERIC(ndp.naaccr_item_value) = 1
          THEN COALESCE(CAST(ndp.naaccr_item_value AS float), conc_num.value_as_number)
      ELSE NULL
    END as value_as_number
      , ndp.value_concept_id                                                                                                                          AS value_as_concept_id
      , COALESCE(unit_cr.concept_id_2, conc_num.unit_concept_id)                                                                                                  AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , ndp.variable_concept_code                                                                                                                                         AS measurement_source_value
      , ndp.variable_concept_id                                                                                                                                         AS measurement_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , naaccr_item_value                                                                                                                                         AS value_source_value
      , et.episode_id                                                                                                                             AS modifier_of_event_id
      , 1000000003 -- TODO: Need vocab update                                                                                                                  AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT *
    FROM naaccr_data_points_tmp
    WHERE person_id IS NOT NULL
    -- concept is modifier of a diagnosis item (child of site/hist)
    AND variable_concept_id IN (  SELECT DISTINCT concept_id_1
                    FROM concept_relationship
                    WHERE relationship_id = 'Has parent item'
                    AND concept_id_2 in (35918686  --Phase I Radiation Treatment Modality
                              ,35918378  --Phase II Radiation Treatment Modality
                              ,35918255  --Phase III Radiation Treatment Modality
                              ,35918593  --RX Summ--Surg Prim Site
                              )
                    )
    -- filter empty values
    AND LEN(naaccr_item_value) > 0

   ) ndp

   -- Get episode_temp record
    INNER JOIN episode_temp et
    ON ndp.record_id = et.record_id
    -- restrict to treatment episodes
    AND et.episode_source_concept_id IN (
                      35918686  --Phase I Radiation Treatment Modality
                      ,35918378  --Phase II Radiation Treatment Modality
                      ,35918255  --Phase III Radiation Treatment Modality
                      ,35918593  --RX Summ--Surg Prim Site
                      )


  -- Get standard concept
  INNER JOIN concept_relationship cr
    on ndp.variable_concept_id = cr.concept_id_1
    and cr.relationship_id = 'Maps to'
  INNER JOIN concept conc
    on cr.concept_id_2 = conc.concept_id
    AND conc.domain_id = 'Measurement'
    -- AND standard_concept = 'S'    -- Should we add this now or wait?

  -- Get Unit
  LEFT OUTER JOIN concept_relationship unit_cr
    ON ndp.variable_concept_id = unit_cr.concept_id_1
    and unit_cr.relationship_id = 'Has unit'

  -- Get numeric value
  LEFT OUTER JOIN concept_numeric conc_num
    ON ndp.type_concept_id = 32676 --'Numeric'
    AND ndp.value_concept_id = conc_num.concept_id


  ;



--Step 15: Copy Episode Measurements to Procedure Occurrence for Treatment Episodes
INSERT INTO measurement_temp
(
    measurement_id
  , person_id
  , measurement_concept_id
  , measurement_date
  , measurement_time
  , measurement_datetime
  , measurement_type_concept_id
  , operator_concept_id
  , value_as_number
  , value_as_concept_id
  , unit_concept_id
  , range_low
  , range_high
  , provider_id
  , visit_occurrence_id
  , visit_detail_id
  , measurement_source_value
  , measurement_source_concept_id
  , unit_source_value
  , value_source_value
  , modifier_of_event_id
  , modifier_of_field_concept_id
  , record_id
)
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE
  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over(order by mt.record_id)) AS measurement_id
      , mt.person_id                                                                                                                                                      AS person_id
      , mt.measurement_concept_id                                                                                                                                         AS measurement_concept_id
      , mt.measurement_date                                                                                                                                               AS measurement_date
      , mt.measurement_time                                                                                                                                               AS measurement_time
      , mt.measurement_datetime                                                                                                                                           AS measurement_datetime
      , mt.measurement_type_concept_id                                                                                                                                    AS measurement_type_concept_id
      , mt.operator_concept_id                                                                                                                                            AS operator_concept_id
      , mt.value_as_number                                                                                                                                                AS value_as_number
      , mt.value_as_concept_id                                                                                                                                            AS value_as_concept_id
      , mt.unit_concept_id                                                                                                                                                AS unit_concept_id
      , mt.range_low                                                                                                                                                      AS range_low
      , mt.range_high                                                                                                                                                     AS range_high
      , mt.provider_id                                                                                                                                                    AS provider_id
      , mt.visit_occurrence_id                                                                                                                                            AS visit_occurrence_id
      , mt.visit_detail_id                                                                                                                                                AS visit_detail_id
      , mt.measurement_source_value                                                                                                                                       AS measurement_source_value
      , mt.measurement_source_concept_id                                                                                                                                  AS measurement_source_concept_id
      , mt.unit_source_value                                                                                                                                              AS unit_source_value
      , mt.value_source_value                                                                                                                                             AS value_source_value
      , pet.procedure_occurrence_id                                                                                                                                       AS modifier_of_event_id
      , 1147084                                                                                                                                                        AS modifier_field_concept_id -- ‘procedure_occurrence.procedure_concept_id’ concept
      , mt.record_id                                                                                                                                                     AS record_id
FROM measurement_temp mt
JOIN episode_temp et
  ON mt.record_id = et.record_id
  AND et.episode_concept_id = 32531 --Treatment Regimen
JOIN procedure_occurrence_temp pet
  ON et.record_id = pet.record_id
  AND et.episode_object_concept_id = pet.procedure_concept_id;









--Step 16: Connect 'Treatment Episodes' to 'Disease Episodes' via parent_id
UPDATE episode_temp
SET episode_parent_id = det.episode_id
FROM episode_temp det
WHERE record_id        = det.record_id
AND episode_concept_id = 32531 --Treatment Regimen
AND det.episode_concept_id          = 32528; --Disease First Occurrence



--Step 16: Connect 'Treatment Episodes' to 'Disease Episodes' via parent_id
UPDATE episode_temp
SET episode_parent_id = det.episode_id
FROM episode_temp det
WHERE record_id        = det.record_id
AND episode_concept_id = 32531 --Treatment Regimen
AND det.episode_concept_id          = 32528; --Disease First Occurrence


-- INSERT TEMP TABLES

  --Step 18: Move episode_temp into episode
  INSERT INTO episode
  (
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
    , episode_number
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
  )
  SELECT
    episode_id
    , person_id
    , episode_concept_id
    , episode_start_datetime
    , episode_end_datetime
    , episode_parent_id
  --  , episode_number
  --  , record_id
    , 0 -- TOOD: What are we putting here? record_id cannot be inserted as it contains text characters
    , episode_object_concept_id
    , episode_type_concept_id
    , episode_source_value
    , episode_source_concept_id
  FROM episode_temp;

  -- Move procedure_occurrence_temp into procedure_occurrence
   INSERT INTO procedure_occurrence
  (
     procedure_occurrence_id
   , person_id
   , procedure_concept_id
   , procedure_date
   , procedure_datetime
   , procedure_type_concept_id
   , modifier_concept_id
   , quantity
   , provider_id
   , visit_occurrence_id
   , visit_detail_id
   , procedure_source_value
   , procedure_source_concept_id
   , modifier_source_value
  )
  SELECT   procedure_occurrence_id
       , person_id
       , procedure_concept_id
       , procedure_date
       , procedure_datetime
       , procedure_type_concept_id
       , COALESCE(modifier_concept_id, 0)
       , quantity
       , provider_id
       , visit_occurrence_id
       , visit_detail_id
       , procedure_source_value
       , procedure_source_concept_id
       , modifier_source_value
  FROM procedure_occurrence_temp;

  --Move drug_exposure_temp into drug_exposure
   INSERT INTO drug_exposure
  (
    drug_exposure_id
    , person_id
    , drug_concept_id
    , drug_exposure_start_date
    , drug_exposure_start_datetime
    , drug_exposure_end_date
    , drug_exposure_end_datetime
    , verbatim_end_date
    , drug_type_concept_id
    , stop_reason
    , refills
    , quantity
    , days_supply
    , sig
    , route_concept_id
    , lot_number
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , drug_source_value
    , drug_source_concept_id
    , route_source_value
    , dose_unit_source_value
  )
  SELECT  drug_exposure_id
      , person_id
      , 0 --We are hardcoding to 0
      , drug_exposure_start_date
      , drug_exposure_start_datetime
      , drug_exposure_end_date
      , drug_exposure_end_datetime
      , verbatim_end_date
      , drug_type_concept_id
      , stop_reason
      , refills
      , quantity
      , days_supply
      , sig
      , COALESCE(route_concept_id,0)
      , lot_number
      , provider_id
      , visit_occurrence_id
      , visit_detail_id
      , drug_source_value
      , drug_source_concept_id
      , route_source_value
      , dose_unit_source_value
  FROM drug_exposure_temp;

  -- Move episode_event_temp into episode_event
  INSERT INTO episode_event
  (
    episode_id
    , event_id
    , episode_event_field_concept_id

  )
  SELECT  episode_id
      , event_id
      , episode_event_field_concept_id
  FROM episode_event_temp;


  -- Move measurement_temp into measurement
  INSERT INTO measurement
  (
      measurement_id
    , person_id
    , measurement_concept_id
    , measurement_date
    , measurement_time
    , measurement_datetime
    , measurement_type_concept_id
    , operator_concept_id
    , value_as_number
    , value_as_concept_id
    , unit_concept_id
    , range_low
    , range_high
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , measurement_source_value
    , measurement_source_concept_id
    , unit_source_value
    , value_source_value
    , modifier_of_event_id
    , modifier_of_field_concept_id
  )
  SELECT
      measurement_id
    , person_id
    , measurement_concept_id
    , measurement_date
    , measurement_time
    , measurement_datetime
    , measurement_type_concept_id
    , operator_concept_id
    , value_as_number
    , value_as_concept_id
    , unit_concept_id
    , range_low
    , range_high
    , provider_id
    , visit_occurrence_id
    , visit_detail_id
    , measurement_source_value
    , measurement_source_concept_id
    , unit_source_value
    , value_source_value
    , modifier_of_event_id
    , modifier_of_field_concept_id
  FROM measurement_temp;




/**
TODO: To be used in another script?


-- Populate person table ( to retain death )


Insert new:
  // ISSUE: Cant have null year_of_birth.

  Insert (...)
  SELECT per.person_id, dth_dates.max_dth_date
   FROM
   (
    SELECT DISTINCT person_id
    FROM naaccr_data_points_tmp ndp
   ) per
   LEFT OUTER JOIN
   (
    SELECT ndp.person_id, MAX(ndp.naaccr_item_value) max_dth_date
    FROM naaccr_data_points_tmp ndp
    INNER JOIN naaccr_data_points_tmp ndp2
      ON ndp.naaccr_item_number = 1750
      AND ndp2.naaccr_item_number = 1760
      AND ndp.naaccr_item_value IS NOT NULL
      AND ndp2.naaccr_item_value = 1
    GROUP BY ndp.person_id
   ) dth_dates
   ON per.person_id = dth_dates.person_id
   ;




-- Update existing person table:

  UPDATE person
  SET death_datetime = dth.max_dth_date
  FROM person per
  INNER JOIN
  (
     SELECT per.person_id, dth_dates.max_dth_date
     FROM
     (
      SELECT DISTINCT person_id
      FROM naaccr_data_points_tmp ndp
     ) per
     LEFT OUTER JOIN
     (
      SELECT ndp.person_id, MAX(ndp.naaccr_item_value) max_dth_date
      FROM naaccr_data_points_tmp ndp
      INNER JOIN naaccr_data_points_tmp ndp2
        ON ndp.naaccr_item_number = 1750
        AND ndp2.naaccr_item_number = 1760
        AND ndp.naaccr_item_value IS NOT NULL
        AND ndp2.naaccr_item_value = 1
      GROUP BY ndp.person_id
     ) dth_dates
     ON per.person_id = dth_dates.person_id
  ) dth
  ON per.person_id = dth.person_id
  --AND per.death_datetime IS NULL
    ;


**/






--Cleanup
--Delete temp tables

IF OBJECT_ID('naaccr_data_points_tmp', 'U') IS NOT NULL           -- Drop temp table if it exists
	  DROP TABLE naaccr_data_points_tmp;  

IF OBJECT_ID('condition_occurrence_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE condition_occurrence_temp;  

IF OBJECT_ID('measurement_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE measurement_temp;  

IF OBJECT_ID('episode_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE episode_temp;  

IF OBJECT_ID('episode_event_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE episode_event_temp;  

IF OBJECT_ID('procedure_occurrence_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE procedure_occurrence_temp;  

IF OBJECT_ID('drug_exposure_temp', 'U') IS NOT NULL           -- Drop temp table if it exists
	DROP TABLE drug_exposure_temp;  


COMMIT;