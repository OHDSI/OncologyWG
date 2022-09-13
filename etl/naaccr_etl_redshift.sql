BEGIN TRANSACTION;

/* Scripts assumes:
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
	Person
	Death
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
		-fact_relationship
	Update Observation_Perod
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

DELETE FROM fact_relationship
WHERE domain_concept_id_1 = 32527;

DELETE FROM episode;

DELETE FROM episode_event;

DELETE FROM cdm_source_provenance;


-- Create temporary tables


DROP TABLE IF EXISTS condition_occurrence_temp;

CREATE TABLE condition_occurrence_temp
 (condition_occurrence_id        BIGINT        NOT NULL ,
   person_id BIGINT        NOT NULL ,
  condition_concept_id          INT        NOT NULL ,
  condition_start_date          DATE          NOT NULL ,
  condition_start_datetime      TIMESTAMP     NULL ,
  condition_end_date            DATE          NULL ,
  condition_end_datetime        TIMESTAMP     NULL ,
  condition_type_concept_id     INT        NOT NULL ,
  stop_reason                   VARCHAR(20)    NULL ,
  provider_id                   BIGINT        NULL ,
  visit_occurrence_id           BIGINT        NULL ,
  --1/23/2019 Removing because we are trying to match the EDW's OMOP instance.
  -- visit_detail_id               BIGINT     NULL ,
  condition_source_value        VARCHAR(50)    NULL ,
  condition_source_concept_id   INT        NULL ,
  condition_status_source_value  VARCHAR(50)   NULL ,
  condition_status_concept_id    INT        NULL,
  record_id                     varchar(255)  NULL
)
DISTKEY(person_id);

DROP TABLE IF EXISTS measurement_temp;

CREATE TABLE measurement_temp
 (measurement_id                BIGINT       NOT NULL ,
   person_id BIGINT       NOT NULL ,
  measurement_concept_id        INT       NOT NULL ,
  measurement_date              DATE         NOT NULL ,
  measurement_time              VARCHAR(10)  NULL ,
  measurement_datetime          TIMESTAMP    NULL ,
  measurement_type_concept_id   INT       NOT NULL ,
  operator_concept_id           INT       NULL ,
  value_as_number               NUMERIC      NULL ,
  value_as_concept_id           INT       NULL ,
  unit_concept_id               INT       NULL ,
  range_low                     NUMERIC      NULL ,
  range_high                    NUMERIC      NULL ,
  provider_id                   BIGINT       NULL ,
  visit_occurrence_id           BIGINT       NULL ,
  visit_detail_id               BIGINT       NULL ,
  measurement_source_value      VARCHAR(50)   NULL ,
  measurement_source_concept_id INT       NULL ,
  unit_source_value             VARCHAR(50)  NULL ,
  value_source_value            VARCHAR(50)  NULL ,
  modifier_of_event_id          BIGINT       NULL ,
  modifier_of_field_concept_id  INT       NULL,
  record_id                     VARCHAR(255) NULL
)
DISTKEY(person_id);

DROP TABLE IF EXISTS episode_temp;

CREATE TABLE episode_temp  (episode_id                  BIGINT        NOT NULL,
   person_id BIGINT        NOT NULL,
  episode_concept_id          INT       NOT NULL,
  episode_start_datetime      TIMESTAMP     NULL,       --Fix me
  episode_end_datetime        TIMESTAMP     NULL,
  episode_parent_id           BIGINT        NULL,
  episode_number              INTEGER       NULL,
  episode_object_concept_id   INTEGER       NOT NULL,
  episode_type_concept_id     INTEGER       NOT NULL,
  episode_source_value        VARCHAR(50)   NULL,
  episode_source_concept_id   INTEGER       NULL,
  record_id                   VARCHAR(255)  NULL
)
DISTKEY(person_id);

DROP TABLE IF EXISTS episode_event_temp;

CREATE TABLE episode_event_temp  (episode_id                      BIGINT   NOT NULL,
  event_id                         BIGINT   NOT NULL,
  episode_event_field_concept_id  INT NOT NULL
)
DISTSTYLE ALL;

DROP TABLE IF EXISTS procedure_occurrence_temp;

CREATE TABLE procedure_occurrence_temp
  (procedure_occurrence_id     BIGINT        NOT NULL ,
   person_id BIGINT        NOT NULL ,
  procedure_concept_id        INT        NOT NULL ,
  procedure_date              DATE          NOT NULL ,
  procedure_datetime          TIMESTAMP     NULL ,
  procedure_type_concept_id   INT        NOT NULL ,
  modifier_concept_id         INT        NULL ,
  quantity                    BIGINT        NULL ,
  provider_id                 BIGINT        NULL ,
  visit_occurrence_id         BIGINT        NULL ,
  visit_detail_id             BIGINT        NULL ,
  procedure_source_value      VARCHAR(50)    NULL ,
  procedure_source_concept_id  INT        NULL ,
  modifier_source_value       VARCHAR(50)    NULL,
  episode_id                  BIGINT        NOT NULL,
  record_id                   VARCHAR(255)  NULL
 )
DISTKEY(person_id);

 DROP TABLE IF EXISTS drug_exposure_temp;

CREATE TABLE drug_exposure_temp
 (drug_exposure_id              BIGINT        NOT NULL ,
   person_id BIGINT        NOT NULL ,
  drug_concept_id               INT        NOT NULL ,
  drug_exposure_start_date      DATE          NOT NULL ,
  drug_exposure_start_datetime  TIMESTAMP      NULL ,
  drug_exposure_end_date        DATE          NULL ,
  drug_exposure_end_datetime    TIMESTAMP      NULL ,
  verbatim_end_date             DATE          NULL ,
  drug_type_concept_id          INT        NOT NULL ,
  stop_reason                   VARCHAR(20)   NULL ,
  refills                       BIGINT        NULL ,
  quantity                      NUMERIC       NULL ,
  days_supply                   BIGINT        NULL ,
  sig                           VARCHAR(max)          NULL ,
  route_concept_id              INT        NULL ,
  lot_number                    VARCHAR(50)   NULL ,
  provider_id                   BIGINT        NULL ,
  visit_occurrence_id           BIGINT        NULL ,
  visit_detail_id               BIGINT        NULL ,
  drug_source_value             VARCHAR(50)   NULL ,
  drug_source_concept_id        INT        NULL ,
  route_source_value            VARCHAR(50)   NULL ,
  dose_unit_source_value        VARCHAR(50)   NULL,
  record_id                     VARCHAR(255)    NULL
)
DISTKEY(person_id);

 DROP TABLE IF EXISTS observation_period_temp;

CREATE TABLE observation_period_temp
 (observation_period_id int NOT NULL,
	 person_id int NOT NULL,
	observation_period_start_date date NOT NULL,
	observation_period_end_date date NOT NULL,
	period_type_concept_id int NOT NULL
 )
DISTKEY(person_id);


  DROP TABLE IF EXISTS fact_relationship_temp;

  CREATE TABLE fact_relationship_temp
   (domain_concept_id_1             INT           NOT NULL ,
    fact_id_1                     	BIGINT        NOT NULL ,
    domain_concept_id_2        		  INT           NOT NULL ,
    fact_id_2              		   	  BIGINT        NOT NULL ,
    relationship_concept_id         INT           NOT NULL ,
    record_id                     	VARCHAR(255)  NULL
  )
DISTSTYLE ALL;



 -- Create ambiguous schema discriminator mapping tables

 DROP TABLE IF EXISTS ambig_schema_discrim;

 CREATE TABLE ambig_schema_discrim (schema_concept_code varchar(50) NULL,
	schema_concept_id INT NULL,
	discrim_item_num varchar(50) NULL,
	discrim_item_value varchar(50) NULL
)
DISTSTYLE ALL;
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



DROP TABLE IF EXISTS naaccr_data_points_temp;

CREATE TABLE naaccr_data_points_temp
 ( person_id BIGINT NOT NULL,
	record_id VARCHAR(255) NULL,
	histology_site VARCHAR(255) NULL,
	naaccr_item_number VARCHAR(255) NULL,
	naaccr_item_value VARCHAR(255) NULL,
	schema_concept_id INT NULL,
	schema_concept_code VARCHAR(255),
	variable_concept_id INT NULL,
	variable_concept_code VARCHAR(255) NULL,
	value_concept_id INT NULL,
	value_concept_code VARCHAR(255) NULL,
	type_concept_id INT NULL
)
DISTKEY(person_id);

DROP TABLE IF EXISTS tmp_naaccr_data_points_temp_dates;

CREATE TABLE tmp_naaccr_data_points_temp_dates
 ( person_id BIGINT NOT NULL,
	record_id VARCHAR(255) NULL,
	histology_site VARCHAR(255) NULL,
	naaccr_item_number VARCHAR(255) NULL,
	naaccr_item_value VARCHAR(255) NULL,
	schema_concept_id INT NULL,
	schema_concept_code VARCHAR(255),
	variable_concept_id INT NULL,
	variable_concept_code VARCHAR(255) NULL,
	value_concept_id INT NULL,
	value_concept_code VARCHAR(255) NULL,
	type_concept_id INT NULL
)
DISTKEY(person_id);

DROP TABLE IF EXISTS tmp_concept_naaccr_procedures;

CREATE TABLE tmp_concept_naaccr_procedures
 (c1_concept_id INT NULL,
    c1_concept_code VARCHAR(255),
    c2_concept_id INT NULL,
    c2_concept_code VARCHAR(255)
)
DISTSTYLE ALL;


 -- PERSON
-- We need person insert early on in script as it joins on naaccr_data_points_temp insert

	INSERT INTO person
           (
             person_id
           , gender_concept_id
           , year_of_birth
           , month_of_birth
           , day_of_birth
           , birth_datetime
           , race_concept_id
           , ethnicity_concept_id
           , location_id
           , provider_id
           , care_site_id
           , person_source_value
           , gender_source_value
           , gender_source_concept_id
           , race_source_value
           , race_source_concept_id
           , ethnicity_source_value
           , ethnicity_source_concept_id)

  SELECT per.person_id
		,COALESCE(gen.gender_concept_id,0)
		,EXTRACT(YEAR FROM dob)
		,EXTRACT(MONTH FROM dob)
		,EXTRACT(DAY FROM dob)
		,dob
		,COALESCE(race.race_concept_id, 0)
		,COALESCE(ethn.ethnicity_concept_id, 0)
		,NULL
		,NULL
		,NULL
		,NULL
		,gen.naaccr_item_value
		,COALESCE(gen.gender_concept_id,0)
		,race.naaccr_item_value
		,COALESCE(race.race_concept_id, 0)
		,ethn.naaccr_item_value
		,COALESCE(ethn.ethnicity_concept_id, 0)
   FROM
   (
    SELECT DISTINCT person_id,
				CAST(naaccr_item_value as date) dob
    FROM naaccr_data_points ndp
	WHERE naaccr_item_number = '240' -- date of birth
	AND person_id NOT IN ( SELECT person_id FROM person) -- exclude if exists already
  AND ndp.person_id IS NOT NULL
   ) per
   LEFT OUTER JOIN
   (
	SELECT DISTINCT
		person_id
		,naaccr_item_value
		,CASE WHEN naaccr_item_value = '1' THEN 8507
			 WHEN naaccr_item_value = '2' THEN 8532
			 ELSE '0'
		END as gender_concept_id
	FROM naaccr_data_points ndp
	WHERE naaccr_item_number = '220'    -- gender
   ) gen
   ON per.person_id = gen.person_id
   LEFT OUTER JOIN
   (
	SELECT DISTINCT
		person_id
		,naaccr_item_value
		,CASE WHEN naaccr_item_value = '01' THEN 8527		-- white
			 WHEN naaccr_item_value = '02' THEN 8516		-- black
			 WHEN naaccr_item_value = '03' THEN 8657		-- american indian or alaska native
			 WHEN naaccr_item_value = '04' THEN 38003579	-- chinese
			 WHEN naaccr_item_value = '05' THEN 38003584	-- japanese
			 WHEN naaccr_item_value = '06' THEN 38003581	-- filipino
			 WHEN naaccr_item_value = '07' THEN 8557		-- native hawaiian or other pacific islander
			 WHEN naaccr_item_value = '08' THEN 38003585	-- korean
			 WHEN naaccr_item_value = '10' THEN 38003592	-- vietnamese
			 WHEN naaccr_item_value = '11' THEN 38003586	-- laotian
			 WHEN naaccr_item_value = '12' THEN 38003582	-- hmong
			 WHEN naaccr_item_value = '13' THEN 38003578	-- cambodian
			 WHEN naaccr_item_value = '14' THEN 38003591	-- thai
	--TODO	 WHEN naaccr_item_value = '15' THEN ?			-- asian indian or pakistani
			 WHEN naaccr_item_value = '16' THEN 38003574	-- asian indian
			 WHEN naaccr_item_value = '17' THEN 38003589	-- pakistani
			 WHEN naaccr_item_value = '20' THEN 38003611	-- micronesian
	--TODO	 WHEN naaccr_item_value = '21' THEN ?			-- chamorro/chamoru
			 WHEN naaccr_item_value = '22' THEN 4085322		-- guamanian -> oceanian
			 WHEN naaccr_item_value = '25' THEN 38003610	-- polynesian, nos
	--TODO	 WHEN naaccr_item_value = '26' THEN ?			-- tahitian
			 WHEN naaccr_item_value = '27' THEN 4085322		-- samoan -> oceanian
			 WHEN naaccr_item_value = '28' THEN 4085322		-- tongan -> oceanian
			 WHEN naaccr_item_value = '30' THEN 38003612	-- melanesian
			 WHEN naaccr_item_value = '31' THEN 4085322		-- fijian -> oceanian
	--TODO	 WHEN naaccr_item_value = '32' THEN ?			-- new guinean
			 WHEN naaccr_item_value = '96' THEN 8515		-- (other) asian
			 WHEN naaccr_item_value = '37' THEN 38003613	-- other pacific islander
			 ELSE '0'
		END as race_concept_id
	FROM naaccr_data_points ndp
	WHERE naaccr_item_number = '160'    -- race 1
   ) race
   ON per.person_id = race.person_id
   LEFT OUTER JOIN
   (
	SELECT DISTINCT
		person_id
		,naaccr_item_value
		,CASE WHEN naaccr_item_value = '0' THEN 38003564									-- non hispanic or latino
			 WHEN naaccr_item_value IN ('1','2','3','4','5','6','7','8') THEN 38003563	-- hispanic or latino
			 ELSE '0'
		END as ethnicity_concept_id
	FROM naaccr_data_points ndp
	WHERE naaccr_item_number = '190'    -- spanish/hispanic origin
   ) ethn
   ON per.person_id = ethn.person_id
   ;








-- DATA PREP


	 -- Initial data insert
	 INSERT INTO naaccr_data_points_temp
	 SELECT  ndp.person_id
         , record_id
         , histology_site
         , naaccr_item_number
         , CASE WHEN CHAR_LENGTH(naaccr_item_value) > 255
				THEN SUBSTRING(naaccr_item_value,1,255)
				ELSE naaccr_item_value
			END
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
	 FROM naaccr_data_points ndp
	 -- only consider valid person_id
	 INNER JOIN person per
	 ON ndp.person_id = per.person_id
	AND ndp.naaccr_item_value IS NOT NULL
	AND ndp.naaccr_item_value != ''
	AND ndp.naaccr_item_number NOT IN(
     '1810' --ADDR CURRENT--CITY
   );


	-- Format dates
	-- TODO: Add 1750 to this list. Determine if other date fields also dont have relationships
  UPDATE naaccr_data_points_temp
  SET naaccr_item_value =
		CASE
			WHEN CHAR_LENGTH(naaccr_item_value) != 8 THEN NULL
			WHEN REGEXP_INSTR(naaccr_item_value, '^[\-\+]?(\\d*\\.)?\\d+([Ee][\-\+]?\\d+)?$') <> 1 THEN NULL
			ELSE CASE
				WHEN CAST(SUBSTRING(naaccr_item_value, 1,4) as int) NOT BETWEEN 1800 AND 2099 THEN NULL
				WHEN CAST(SUBSTRING(naaccr_item_value, 5,2) as int) NOT BETWEEN 1 AND 12 THEN NULL
				WHEN CAST(SUBSTRING(naaccr_item_value, 7,2) as int) NOT BETWEEN 1 AND 31 THEN NULL
				ELSE naaccr_item_value
				END
		END
  WHERE naaccr_item_number IN(-- todo: verify this list
      SELECT DISTINCT c.concept_code
      FROM concept c
      INNER JOIN concept_relationship cr
        ON  cr.concept_id_1 = c.concept_id
        AND cr.relationship_id IN ('Start date of', 'End date of')
      WHERE c.vocabulary_id = 'NAACCR'
  );






	-- Trim values just in case leading or trailing spaces
	UPDATE naaccr_data_points_temp
	SET naaccr_item_value = LTRIM(RTRIM(naaccr_item_value))
	;

   -- Start with ambiguous schemas
    UPDATE naaccr_data_points_temp
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
        FROM naaccr_data_points_temp
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


    -- Append standard schemas - uses histology_site
    UPDATE naaccr_data_points_temp
    SET schema_concept_id   = schm.concept_id,
        schema_concept_code = schm.concept_code
    FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema' AND c1.vocabulary_id = 'ICDO3'
                    JOIN concept schm             ON cr1.concept_id_2 = schm.concept_id AND schm.vocabulary_id = 'NAACCR'
    WHERE naaccr_data_points_temp.histology_site = c1.concept_code
    AND naaccr_data_points_temp.schema_concept_id IS NULL;

	-- Variables
  -- schema-independent
	-- Variables
  UPDATE naaccr_data_points_temp
    SET variable_concept_code = cv.variable_concept_code
    , variable_concept_id   = cv.variable_concept_id
    FROM
    (
        SELECT DISTINCT
            c1.concept_code                   AS concept_code,
			-- c1.concept_code					  AS variable_concept_code,
			-- c1.concept_id					  AS variable_concept_id
            CASE
                WHEN c2.domain_id = 'Episode'
                THEN c2.concept_code
                ELSE c1.concept_code
            END                               AS variable_concept_code,
            CASE
                WHEN c2.domain_id = 'Episode'
                THEN c2.concept_id
                ELSE c1.concept_id
            END                               AS variable_concept_id
            -- CASE
            --     WHEN COALESCE(c2.standard_concept, '') = 'S'
            --     THEN c1.concept_code
            --     ELSE c2.concept_code
            -- END                               AS variable_concept_code,
            -- CASE
            --     WHEN COALESCE(c1.standard_concept, '') = 'S'
            --     THEN c1.concept_id
            --     ELSE c2.concept_id
            -- END                               AS variable_concept_id
  FROM concept c1
        LEFT JOIN concept_relationship cr1
            ON  c1.concept_id = cr1.concept_id_1
            AND cr1.relationship_id = 'Maps to'
        LEFT JOIN concept c2
            ON cr1.concept_id_2 = c2.concept_id
  WHERE c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Variable'
    ) cv
    WHERE naaccr_data_points_temp.variable_concept_id IS NULL
    AND naaccr_data_points_temp.naaccr_item_number = cv.concept_code;


  --  schema dependent
  UPDATE naaccr_data_points_temp
  SET variable_concept_code = c1.concept_code
    , variable_concept_id   = c1.concept_id
  FROM concept c1
  WHERE c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Variable'
  AND naaccr_data_points_temp.variable_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND CONCAT(naaccr_data_points_temp.schema_concept_code,CONCAT('@',naaccr_data_points_temp.naaccr_item_number)) = c1.concept_code;


  -- schema-independent
  UPDATE naaccr_data_points_temp
  SET variable_concept_code = c1.concept_code
    , variable_concept_id   = c1.concept_id
  FROM concept c1
  WHERE c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Variable'
  AND naaccr_data_points_temp.variable_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND c1.standard_concept IS NULL
  AND naaccr_data_points_temp.naaccr_item_number = c1.concept_code;

  -- Values schema-independent

  UPDATE naaccr_data_points_temp
  SET   value_concept_code = c1.concept_code
      , value_concept_id   = c1.concept_id
  FROM concept c1
  WHERE naaccr_data_points_temp.value_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Value'
  AND CONCAT(naaccr_data_points_temp.variable_concept_code,CONCAT('@',naaccr_data_points_temp.naaccr_item_value)) = c1.concept_code
  AND naaccr_data_points_temp.naaccr_item_number NOT IN(-- todo: verify this list
      SELECT DISTINCT c.concept_code
      FROM concept c
      INNER JOIN concept_relationship cr
        ON  cr.concept_id_1 = c.concept_id
        AND cr.relationship_id IN ('Start date of', 'End date of')
      WHERE c.vocabulary_id = 'NAACCR'
  );

  -- Values schema-independent (handle Observation domain values)

  UPDATE naaccr_data_points_temp
  SET   value_concept_code = c1.concept_code
      , value_concept_id   = c1.concept_id
  FROM concept c1
  WHERE naaccr_data_points_temp.value_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Value'
  AND CONCAT(naaccr_data_points_temp.naaccr_item_number,CONCAT('@',naaccr_data_points_temp.naaccr_item_value)) = c1.concept_code
  AND naaccr_data_points_temp.naaccr_item_number NOT IN(-- todo: verify this list
      SELECT DISTINCT c.concept_code
      FROM concept c
      INNER JOIN concept_relationship cr
        ON  cr.concept_id_1 = c.concept_id
        AND cr.relationship_id IN ('Start date of', 'End date of')
      WHERE c.vocabulary_id = 'NAACCR'
  );

   -- Values schema-dependent
  UPDATE naaccr_data_points_temp
  SET   value_concept_code = c1.concept_code
      , value_concept_id   = c1.concept_id
  FROM concept c1
  WHERE naaccr_data_points_temp.value_concept_id IS NULL
  AND c1.concept_id IS NOT NULL
  AND c1.vocabulary_id = 'NAACCR'
  AND c1.concept_class_id = 'NAACCR Value'
  AND CONCAT(naaccr_data_points_temp.schema_concept_code,CONCAT('@',CONCAT(naaccr_data_points_temp.variable_concept_code,CONCAT('@',naaccr_data_points_temp.naaccr_item_value)))) = c1.concept_code
  AND naaccr_data_points_temp.naaccr_item_number NOT IN(-- todo: verify this list
      SELECT DISTINCT c.concept_code
      FROM concept c
      INNER JOIN concept_relationship cr
        ON  cr.concept_id_1 = c.concept_id
        AND cr.relationship_id IN ('Start date of', 'End date of')
      WHERE c.vocabulary_id = 'NAACCR'
  );

  -- Type

  UPDATE naaccr_data_points_temp
  SET type_concept_id = cr1.concept_id_2
  FROM concept_relationship cr1
  WHERE cr1.relationship_id = 'Has type'
  AND naaccr_data_points_temp.variable_concept_id = cr1.concept_id_1;


  -- Building indexes to optimize performance

  -- redshift does not support indexes
  -- redshift does not support indexes
  -- redshift does not support indexes
  -- redshift does not support indexes

   -- DEATH

	INSERT INTO death
           (
             person_id
           , death_date
           , death_datetime
           , death_type_concept_id
           , cause_concept_id
           , cause_source_value
           , cause_source_concept_id
           )
	SELECT
		person_id
		,max_dth_date
		,max_dth_date
		,0 -- TODO
		,0 -- TODO
		,NULL
		,0
	FROM
	(
		SELECT ndp.person_id
				,CAST(MAX(ndp.naaccr_item_value) as date) max_dth_date
		FROM naaccr_data_points ndp
		INNER JOIN naaccr_data_points ndp2
		  ON ndp.naaccr_item_number = '1750'		-- date of last contact
		  AND ndp2.naaccr_item_number = '1760'	-- vital status
		  AND ndp.naaccr_item_value IS NOT NULL
		  AND CHAR_LENGTH(ndp.naaccr_item_value) = '8'
		  AND ndp2.naaccr_item_value = '0' --'0'='Dead'
		  AND ndp.record_id = ndp2.record_id
      AND ndp.person_id IS NOT NULL
		GROUP BY ndp.person_id
	) x
	WHERE x.person_id NOT IN (SELECT person_id from DEATH)
	;




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

  SELECT COALESCE( (SELECT MAX(condition_occurrence_id) FROM condition_occurrence_temp)
                 , (SELECT MAX(condition_occurrence_id) FROM condition_occurrence)
                 , 0) + ROW_NUMBER() OVER (ORDER BY s.person_id )                                                                  AS condition_occurrence_id
      , s.person_id                                                                                           AS person_id
      , c2.concept_id                                                                                         AS condition_concept_id
      , CAST(s.naaccr_item_value as date)  		                                                          AS condition_start_date
      , CAST(s.naaccr_item_value as date)																  AS condition_start_datetime
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
      SELECT person_id
        	 , record_id
        	 , histology_site
        	 , naaccr_item_number
        	 , naaccr_item_value
        	 , schema_concept_id
        	 , schema_concept_code
        	 , variable_concept_id
        	 , variable_concept_code
        	 , value_concept_id
        	 , value_concept_code
        	 , type_concept_id
      FROM naaccr_data_points_temp
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

  -- Initial Diagnosis Condition Modifier

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


  SELECT COALESCE((SELECT MAX(measurement_id) FROM measurement), 0) + ROW_NUMBER() OVER (ORDER BY cot.person_id )                                                AS measurement_id
      , cot.person_id                                                                                                                                           AS person_id
      , 32528 																																				  AS measurement_concept_id  --'Disease First Occurrence'
      , cot.condition_start_date                                                                                                                                AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                                            						AS operator_concept_id
      , NULL 																																					AS value_as_number
      , NULL                                                                                                                          							AS value_as_concept_id
      , NULL                                                                                                  													AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , NULL                                                                                                                                         			AS measurement_source_value
      ,32528                                                                                                                                         		    AS measurement_source_concept_id --'Disease First Occurrence'
      , NULL                                                                                                                                                    AS unit_source_value
      , NULL                                                                                                                                         			AS value_source_value
      , cot.condition_occurrence_id                                                                                                                             AS modifier_of_event_id
      , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
      , cot.record_id                                                                                                                                           AS record_id
  FROM condition_occurrence_temp cot;

  -- Staging Cancer Modifiers

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

 	/*
 	 EXAMPLE OF TNM INSERT
 	 using TNM PATH T
 	*/
     SELECT COALESCE((SELECT MAX(measurement_id) FROM measurement_temp), 0) + ROW_NUMBER() OVER (ORDER BY conc.person_id )   AS measurement_id
         , cot.person_id                      	AS person_id
         , conc.concept_id                    	AS measurement_concept_id
         , cot.condition_start_date           	AS measurement_date
         , NULL                               	AS measurement_time
         , cot.condition_start_datetime       	AS measurement_datetime
         , 32534								AS measurement_type_concept_id -- 'Tumor registry' concept
         , NULL							    	AS operator_concept_id
         , NULL									AS value_as_number
         , NULL									AS value_as_concept_id
         , NULL									AS unit_concept_id
         , NULL									AS range_low
         , NULL									AS range_high
         , NULL                              	AS provider_id
         , NULL                              	AS visit_occurrence_id
         , NULL                              	AS visit_detail_id
         , tnm_concept_code                  	AS measurement_source_value
         , conc.concept_id		            	AS measurement_source_concept_id
         , NULL                              	AS unit_source_value
         , tnm_value_raw  						AS value_source_value
         , cot.condition_occurrence_id			AS modifier_of_event_id
         , 1147127								AS modifier_field_concept_id -- 'condition_occurrence.condition_occurrence_id' concept
         , cot.record_id						AS record_id
     FROM condition_occurrence_temp cot

 	-- GET TNM CONCEPT
 	INNER JOIN
     (
 	 -- get record_id + concept_code + concept_id

 		SELECT record_id, person_id, tnm.tnm_concept_code, conc.concept_id, tnm.tnm_value_raw
 		FROM
 		(
 			-- hardcode 'p-' to start for PATH to match concept code of target
 			-- Get the TNM concept code to join
 			-- X = TNM value
 			-- Y = TNM edition
 			SELECT    x.record_id
					, x.person_id
 					, x.tnm_value_raw
 					, CONCAT(tnm_type_indicator,CONCAT(y.tnm_edition,CONCAT('th_AJCC/UICC-',x.tnm_value))) as tnm_concept_code
 			FROM
 			(
 				-- Get the TNM VALUE, one for each,  unioned (need split for concept code derivation)

 				--  T ----------------------------------
 				SELECT DISTINCT   record_id
								, person_id
 								, CONCAT(substring(naaccr_item_value, 1,1), '-') as tnm_type_indicator
 								, CONCAT('T',substring(naaccr_item_value, 2, 10)) as tnm_value
 								, naaccr_item_value as tnm_value_raw
 				FROM naaccr_data_points_temp
 				WHERE naaccr_item_number in (
 					  '880'
 					, '940'
 					, '1001'
 					, '1011'
 				)
 				-- filter out null records
 				AND CHAR_LENGTH(naaccr_item_value) > 0
 				AND naaccr_item_value <> '88'
 				UNION

 				-- N ----------------------------------------
 				SELECT DISTINCT   record_id
								, person_id
 								, CONCAT(substring(naaccr_item_value, 1,1), '-') as tnm_type_indicator
 								, CONCAT('N',substring(naaccr_item_value, 2, 10)) as tnm_value
 								, naaccr_item_value as tnm_value_raw
 				FROM naaccr_data_points_temp
 				WHERE naaccr_item_number in (
 					  '890'
 					, '950'
 					, '1002'
 					, '1012'
 				)
 				-- filter out null records
 				AND CHAR_LENGTH(naaccr_item_value) > 0
 				AND naaccr_item_value <> '88'
 				UNION

 				-- M ------------------------------------
 				SELECT DISTINCT   record_id
								, person_id
 								, CONCAT(substring(naaccr_item_value, 1,1), '-') as tnm_type_indicator
 								, CONCAT('M',substring(naaccr_item_value, 2, 10)) as tnm_value
 								, naaccr_item_value as tnm_value_raw
 				FROM naaccr_data_points_temp
 				WHERE naaccr_item_number in (
 					  '900'
 					, '960'
 					, '1003'
 					, '1013'
 				)
 				-- filter out null records
 				AND CHAR_LENGTH(naaccr_item_value) > 0
 				AND naaccr_item_value <> '88'
 				) x
 			INNER JOIN
 			(
 				-- Get the TNM EDITION
 				SELECT DISTINCT record_id
 								-- hacky way to try to get rid of preceeding 0 if it exists
								, person_id
 								, CAST(CAST(naaccr_item_value as int)as varchar) as  tnm_edition
 				FROM naaccr_data_points_temp
 				WHERE naaccr_item_number = '1060' -- TNM Edition Number
 				-- filter out null records
 				AND CHAR_LENGTH(naaccr_item_value) > 0
 				AND naaccr_item_value <> '88'
 				) y
 				ON x.record_id = y.record_id
 			) tnm
 			INNER JOIN concept conc
 				ON conc.vocabulary_id = 'Cancer Modifier'
 				AND conc.concept_class_id = 'Staging/Grading'
 				AND tnm.tnm_concept_code = conc.concept_code
 	) conc
 	ON cot.record_id = conc.record_id
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


    SELECT COALESCE((SELECT MAX(measurement_id) FROM measurement_temp), 0) + ROW_NUMBER() OVER (ORDER BY ndp.person_id )                                                                                                                      AS measurement_id
        , ndp.person_id                                                                                                                                             AS person_id
        , ndp.variable_concept_id
        , cot.condition_start_date                                                                                                                                AS measurement_date
        , NULL                                                                                                                                                    AS measurement_time
        , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
        , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
        , conc_num.operator_concept_id                                                                                                                            AS operator_concept_id
        , CASE
				  WHEN ndp.type_concept_id = 32676 --'Numeric'
						THEN
							CASE
							WHEN ndp.value_concept_id IS NULL AND REGEXP_INSTR(ndp.naaccr_item_value, '^[\-\+]?(\\d*\\.)?\\d+([Ee][\-\+]?\\d+)?$') = 1
							THEN
								CAST(ndp.naaccr_item_value AS NUMERIC)
							ELSE
								COALESCE(conc_num.value_as_number, NULL)
							END
					  ELSE
						NULL
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
      SELECT person_id
        	 , record_id
        	 , histology_site
        	 , naaccr_item_number
        	 , naaccr_item_value
        	 , schema_concept_id
        	 , schema_concept_code
        	 , variable_concept_id
        	 , variable_concept_code
        	 , value_concept_id
        	 , value_concept_code
        	 , type_concept_id
      FROM naaccr_data_points_temp

      -- concept is modifier of a diagnosis item (child of site/hist)
      WHERE variable_concept_id IN (  SELECT DISTINCT concept_id_1
                      FROM concept_relationship
                      WHERE relationship_id = 'Has parent item'
                      AND concept_id_2 in (35918588 -- primary site
                                ,35918916 -- histology
                                )
                      )
      -- filter empty values
      AND CHAR_LENGTH(naaccr_item_value) > 0

     ) ndp

     -- Get condition_occurrence record
      INNER JOIN condition_occurrence_temp cot
      ON ndp.record_id = cot.record_id

--    -- Get standard concept
--    INNER JOIN concept_relationship cr
--      on ndp.variable_concept_id = cr.concept_id_1
--      and cr.relationship_id = 'Maps to'
--    INNER JOIN concept conc
--      on cr.concept_id_2 = conc.concept_id
--      AND conc.domain_id = 'Measurement'

    -- Get Unit
    LEFT OUTER JOIN concept_relationship unit_cr
      ON ndp.variable_concept_id = unit_cr.concept_id_1
      and unit_cr.relationship_id = 'Has unit'

    -- Get numeric value
    LEFT OUTER JOIN concept_numeric conc_num
      ON ndp.type_concept_id = 32676 --'Numeric'
      AND ndp.value_concept_id = conc_num.concept_id
    ;



-- Treatment Episodes
  -- Temp table with NAACCR dates
  -- Used in joins instead full naaccr_data_points table to improve performance

  INSERT INTO tmp_naaccr_data_points_temp_dates 
  SELECT *
  FROM naaccr_data_points_temp src
  WHERE EXISTS
    (
      SELECT 1
      FROM concept_relationship cr
      WHERE cr.concept_id_1 = src.variable_concept_id
        AND cr.relationship_id IN ('End date of', 'Start date of')
    );

  -- redshift does not support indexes


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
  SELECT COALESCE( (SELECT MAX(episode_id) FROM episode_temp)
                 , (SELECT MAX(episode_id) FROM episode)
                 , 0) + ROW_NUMBER() OVER (ORDER BY ndp.person_id )                                                                                                                     AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , ndp.variable_concept_id  -- 32531 Treatment regimen
      , CAST(ndp_dates.naaccr_item_value as date)  		                                                          AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , c2.concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , c2.concept_code                                                                                                     AS episode_source_value
      , c2.concept_id                                                                                                                                           AS episode_source_concept_id
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT person_id
      	 , record_id
      	 , histology_site
      	 , naaccr_item_number
      	 , naaccr_item_value
      	 , schema_concept_id
      	 , schema_concept_code
      	 , variable_concept_id
      	 , variable_concept_code
      	 , value_concept_id
      	 , value_concept_code
      	 , type_concept_id
    FROM naaccr_data_points_temp
    WHERE naaccr_item_number IN ( '1390', '1400', '1410')
  ) ndp
	--Get value
  INNER JOIN concept c1 ON c1.concept_class_id = 'NAACCR Variable' AND ndp.naaccr_item_number = c1.concept_code
	INNER JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has Answer'
	INNER JOIN concept c2 ON cr1.concept_id_2 = c2.concept_id AND CONCAT(c1.concept_code,CONCAT('@',ndp.naaccr_item_value)) = c2.concept_code
  -- Get start date
  INNER JOIN concept_relationship cr2 ON c1.concept_id = cr2.concept_id_1
    AND cr2.relationship_id = 'Has start date'
  INNER JOIN tmp_naaccr_data_points_temp_dates ndp_dates
    ON cr2.concept_id_2 = ndp_dates.variable_concept_id
    AND ndp.record_id = ndp_dates.record_id
	-- filter null dates
	AND ndp_dates.naaccr_item_value IS NOT NULL;


  -- Temp table with concept_ids only to optimize insert query
  INSERT INTO tmp_concept_naaccr_procedures
  SELECT
    c1.concept_id     AS c1_concept_id,
    c1.concept_code   AS c1_concept_code,
    c2.concept_id     AS c2_concept_id,
    c2.concept_code   AS c2_concept_code
  FROM concept c1
  INNER JOIN concept_relationship cr1
    ON  c1.concept_id = cr1.concept_id_1
    AND cr1.relationship_id = 'Has Answer'
  INNER JOIN concept c2
    ON  cr1.concept_id_2 = c2.concept_id
    AND c2.domain_id = 'Procedure'
  WHERE c1.vocabulary_id = 'NAACCR'
    AND c1.concept_class_id = 'NAACCR Variable'
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
  SELECT COALESCE( (SELECT MAX(episode_id) FROM episode_temp)
                 , (SELECT MAX(episode_id) FROM episode)
                 , 0) + ROW_NUMBER() OVER (ORDER BY ndp.person_id )                                                                                                                       AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , ndp.variable_concept_id  -- 32531 Treatment regimen
      , CAST(ndp_dates.naaccr_item_value as date)  		                                                          AS episode_start_datetime        --?
      -- Placeholder... TODO:better universal solution for isnull?
	    , CASE WHEN CHAR_LENGTH(end_dates.naaccr_item_value) > 1
			 THEN CAST(end_dates.naaccr_item_value as date)
			 ELSE NULL
			 END AS episode_end_datetime
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , c.c2_concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , c.c2_concept_code                                                                                                     																		AS episode_source_value
      , c.c2_concept_id
      , ndp.record_id                                                                                                                                             AS record_id
  FROM
  (
    SELECT person_id
      	 , record_id
      	 , histology_site
      	 , naaccr_item_number
      	 , naaccr_item_value
      	 , schema_concept_id
      	 , schema_concept_code
      	 , variable_concept_id
      	 , variable_concept_code
      	 , value_concept_id
      	 , value_concept_code
      	 , type_concept_id
    FROM naaccr_data_points_temp
    WHERE naaccr_item_number NOT IN ( '1290' )
  ) ndp
  INNER JOIN tmp_concept_naaccr_procedures c
    ON CONCAT(c.c1_concept_code,CONCAT('@',ndp.naaccr_item_value)) = c.c2_concept_code
    AND ndp.naaccr_item_number = c.c1_concept_code
  INNER JOIN concept_relationship cr2
    ON c.c1_concept_id = cr2.concept_id_1
    AND cr2.relationship_id = 'Has start date'
  INNER JOIN tmp_naaccr_data_points_temp_dates ndp_dates
    ON cr2.concept_id_2 = ndp_dates.variable_concept_id
	-- filter null dates
	AND ndp_dates.naaccr_item_value IS NOT NULL
    AND ndp.record_id = ndp_dates.record_id
  -- Get end date
  LEFT OUTER JOIN concept_relationship cr3
    ON c.c1_concept_id = cr3.concept_id_1
    AND cr3.relationship_id = 'Has end date'
  LEFT OUTER JOIN tmp_naaccr_data_points_temp_dates end_dates
    ON cr3.concept_id_2 = end_dates.variable_concept_id
	--ON end_dates.naaccr_item_number = '3220'
	-- filter null dates
	AND end_dates.naaccr_item_value IS NOT NULL
	AND ndp.record_id = end_dates.record_id
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
  SELECT COALESCE( (SELECT MAX(episode_id) FROM episode_temp)
                 , (SELECT MAX(episode_id) FROM episode)
                 , 0) + ROW_NUMBER() OVER (ORDER BY ndp.person_id )                                                                                                                     AS episode_id
      , ndp.person_id                                                                                                                                             AS person_id
      , 32531 -- Treatment regimen
      , CAST(ndp_dates.naaccr_item_value as date)  		                                                          AS episode_start_datetime        --?
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
    SELECT person_id
      	 , record_id
      	 , histology_site
      	 , naaccr_item_number
      	 , naaccr_item_value
      	 , schema_concept_id
      	 , schema_concept_code
      	 , variable_concept_id
      	 , variable_concept_code
      	 , value_concept_id
      	 , value_concept_code
      	 , type_concept_id
    FROM naaccr_data_points_temp
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
    AND CONCAT(schem_conc.concept_code,CONCAT('@',CONCAT(1290,CONCAT('@',ndp.naaccr_item_value)))) = var_conc.concept_code

  -- hardcoded for now until update
  INNER JOIN tmp_naaccr_data_points_temp_dates ndp_dates
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
  SELECT COALESCE( (SELECT MAX(drug_exposure_id) FROM drug_exposure_temp)
                 , (SELECT MAX(drug_exposure_id) FROM drug_exposure)
                 , 0) + ROW_NUMBER() OVER (ORDER BY et.person_id )                             AS drug_exposure_id
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
  SELECT COALESCE( (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence_temp)
                 , (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence)
                 , 0) + ROW_NUMBER() OVER (ORDER BY et.person_id )  AS procedure_occurrence_id
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

  -- redshift does not support indexes

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


	  SELECT COALESCE( (SELECT MAX(measurement_id) FROM measurement_temp)
                   , (SELECT MAX(measurement_id) FROM measurement)
                   , 0) + ROW_NUMBER() OVER (ORDER BY ndp.person_id )                                                                                                                       AS measurement_id
	      , ndp.person_id                                                                                                                                             AS person_id
	      , conc.concept_id                                                                                                                                        AS measurement_concept_id
	      , et.episode_start_datetime                                                                                                                           AS measurement_time
	      , NULL
	      , et.episode_start_datetime
	      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
	      , conc_num.operator_concept_id                                                                                                                            AS operator_concept_id
	      , CASE
				  WHEN ndp.type_concept_id = 32676 --'Numeric'
						THEN
							CASE
							WHEN ndp.value_concept_id IS NULL AND REGEXP_INSTR(ndp.naaccr_item_value, '^[\-\+]?(\\d*\\.)?\\d+([Ee][\-\+]?\\d+)?$') = 1
							THEN
								CAST(ndp.naaccr_item_value AS NUMERIC)
							ELSE
								COALESCE(conc_num.value_as_number, NULL)
							END
					  ELSE
						NULL
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
	      , 1000000003 -- TODO: Need vocab update                                                                                                                  AS modifier_field_concept_id -- ‘episode.episode_id’ concept
	      , ndp.record_id                                                                                                                                             AS record_id
	  FROM
	  (
      SELECT person_id
        	 , record_id
        	 , histology_site
        	 , naaccr_item_number
        	 , naaccr_item_value
        	 , schema_concept_id
        	 , schema_concept_code
        	 , variable_concept_id
        	 , variable_concept_code
        	 , value_concept_id
        	 , value_concept_code
        	 , type_concept_id
	    FROM naaccr_data_points_temp
	    WHERE person_id IS NOT NULL
	    AND CHAR_LENGTH(naaccr_item_value) > 0

	   ) ndp
		 INNER JOIN concept_relationship cr1 ON ndp.variable_concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has parent item'
	   AND cr1.concept_id_2 in (
			 												  35918686  --Phase I Radiation Treatment Modality
	            	 							, 35918378  --Phase II Radiation Treatment Modality
	 													 	, 35918255  --Phase III Radiation Treatment Modality
	 													 	, 35918593  --RX Summ--Surg Prim Site
														 )
	   -- Get episode_temp record
	    INNER JOIN episode_temp et
	    ON ndp.record_id = et.record_id
	    -- restrict to treatment episodes
	    	AND et.episode_concept_id = 32531
			INNER JOIN concept_relationship cr2 ON et.episode_source_concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Answer of' AND cr1.concept_id_2 = cr2.concept_id_2
	  -- Get standard concept
	  INNER JOIN concept_relationship cr
	    on ndp.variable_concept_id = cr.concept_id_1
	    and cr.relationship_id = 'Maps to'
	  INNER JOIN concept conc
	    on cr.concept_id_2 = conc.concept_id
	    AND conc.domain_id = 'Measurement'

	  -- Get Unit
	  LEFT OUTER JOIN concept_relationship unit_cr
	    ON ndp.variable_concept_id = unit_cr.concept_id_1
	    and unit_cr.relationship_id = 'Has unit'

	  -- Get numeric value
	  LEFT OUTER JOIN concept_numeric conc_num
	    ON ndp.type_concept_id = 32676 --'Numeric'
	    AND ndp.value_concept_id = conc_num.concept_id ;



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
	SELECT COALESCE(   (SELECT MAX(measurement_id) FROM measurement_temp)
                   , (SELECT MAX(measurement_id) FROM measurement)
                   , 0) + ROW_NUMBER() OVER (ORDER BY mt.person_id )                                                                                                                               AS measurement_id
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
		AND mt.modifier_of_event_id = et.episode_id
		  AND mt.modifier_of_field_concept_id = 1000000003
	JOIN procedure_occurrence_temp pet
	  ON et.record_id = pet.record_id
	  AND et.episode_object_concept_id = pet.procedure_concept_id;





	--Step 16: Connect 'Treatment Episodes' to 'Disease Episodes' via parent_id
	UPDATE episode_temp
	SET episode_parent_id = det.episode_id
	FROM
	(
		SELECT DISTINCT record_id rec_id, episode_id
		FROM episode_temp
		WHERE episode_concept_id          = 32528 --Disease First Occurrence
	) det
	WHERE record_id        = det.rec_id
	AND episode_concept_id = 32531; --Treatment Regimen

-- INSERT TEMP TABLES

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
      , stop_reason
      , provider_id
      , visit_occurrence_id
      --, visit_detail_id
      , condition_source_value
      , condition_source_concept_id
      , condition_status_source_value
      , condition_status_concept_id
    FROM condition_occurrence_temp
    ;

    INSERT INTO cdm_source_provenance
    (
      cdm_event_id
    , cdm_field_concept_id
    , record_id
    )
    SELECT  condition_occurrence_id
        , 1147127   --condition_occurrence.condition_occurrence_id
        , record_id
    FROM condition_occurrence_temp;

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

   INSERT INTO cdm_source_provenance
    (
      cdm_event_id
    , cdm_field_concept_id
    , record_id
    )
    SELECT  procedure_occurrence_id
        , 1147082   --procedure_occurrence.procedure_occurrence_id
        , record_id
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

   INSERT INTO cdm_source_provenance
    (
      cdm_event_id
    , cdm_field_concept_id
    , record_id
    )
    SELECT  drug_exposure_id
        , 1147094   --drug_exposure.drug_exposure_id
        , record_id
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

   INSERT INTO cdm_source_provenance
    (
      cdm_event_id
    , cdm_field_concept_id
    , record_id
    )
    SELECT  measurement_id
        , 1147138   --measurement.measurement_id
        , record_id
    FROM measurement_temp;


  -- move from fact_relationship_temp to fact_relationship
  INSERT INTO fact_relationship
  (
      domain_concept_id_1
    , fact_id_1
    , domain_concept_id_2
    , fact_id_2
    , relationship_concept_id
  )
  SELECT
      domain_concept_id_1
    , fact_id_1
    , domain_concept_id_2
    , fact_id_2
    , relationship_concept_id
  FROM fact_relationship_temp;







--------- Observation period

		INSERT INTO observation_period_temp	(
								    observation_period_id
									, person_id
									, observation_period_start_date
									, observation_period_end_date
									, period_type_concept_id
									)
    SELECT  COALESCE(   (SELECT MAX(observation_period_id) FROM observation_period_temp)
                      , (SELECT MAX(observation_period_id) FROM observation_period)
                      , 0) + ROW_NUMBER() OVER (ORDER BY obs_dates.person_id )         AS observation_period_id
   				, obs_dates.person_id
   				, obs_dates.min_date as observation_period_start_date
   				, COALESCE(ndp.max_date, obs_dates.max_date) as observation_period_end_date
   				, 44814724 AS period_type_concept_id -- TODO. 44814724-"Period covering healthcare encounters"
		FROM

		-- start date -> find earliest record
		(
			SELECT person_id,
					MIN(min_date) AS min_date
					,MAX(max_date) as max_date
			FROM
			(
				SELECT person_id
							, Min(condition_start_date)  min_date
							, MAX(condition_start_date)  max_date
				FROM condition_occurrence
				GROUP BY person_id
			UNION
				SELECT person_id
						, Min(drug_exposure_start_date)
						, Max(drug_exposure_start_date)
				FROM drug_exposure
				GROUP BY person_id
			UNION
				SELECT person_id
						, Min(procedure_date)
						, Max(procedure_date)
				FROM procedure_occurrence
				GROUP BY person_id
			UNION
				SELECT person_id
						, Min(observation_date)
						, Max(observation_date)
				FROM Observation
				GROUP BY person_id
			UNION
				SELECT person_id
						, Min(measurement_date)
						, Max(measurement_date)
				FROM measurement
				GROUP BY person_id
			UNION
				SELECT person_id
						, Min(death_date)
						, Max(death_date)
				FROM death
				GROUP BY person_id
			) T
			GROUP BY t.PERSON_ID
		) obs_dates
		LEFT OUTER JOIN
		-- end date -> date of last contact
		(
			SELECT person_id
				, CAST(max(naaccr_item_value) as date) max_date
			FROM naaccr_data_points_temp
			WHERE naaccr_item_number = '1750'
			AND naaccr_item_value IS NOT NULL
			AND CHAR_LENGTH(naaccr_item_value) = '8'
			GROUP BY person_id
		) ndp
		ON obs_dates.person_id = ndp.person_id
		;

	-- Update existing obs period

	-- take min and max values of existing obs period and the temp obs period created above

	UPDATE observation_period
	SET observation_period_start_date = obs.observation_period_start_date
		,observation_period_end_date = obs.observation_period_end_date
	FROM
	(
		SELECT
			person_id obs_person_id
			,MIN(observation_period_start_date) observation_period_start_date
			,MAX(observation_period_end_date) observation_period_end_date
		FROM
		(
      SELECT  observation_period_id
          	, person_id
          	, observation_period_start_date
          	, observation_period_end_date
          	, period_type_concept_id

			FROM observation_period
			UNION
      SELECT  observation_period_id
          	, person_id
          	, observation_period_start_date
          	, observation_period_end_date
          	, period_type_concept_id
			FROM observation_period_temp
		) x
		GROUP BY x.person_id
	) obs
	WHERE person_id = obs.obs_person_id
	;

	-- If new person, create new obs period

	INSERT INTO observation_period
           (
            observation_period_id
           ,person_id
           ,observation_period_start_date
           ,observation_period_end_date
           ,period_type_concept_id)
	SELECT
     observation_period_id
    ,person_id
		,MIN(observation_period_start_date) observation_period_start_date
		,MAX(observation_period_end_date) observation_period_end_date
		,44814724	-- TODO
	FROM observation_period_temp
	WHERE person_id NOT IN (select person_id from observation_period)
	GROUP BY observation_period_id, person_id
	;


--Cleanup
--Delete temp tables

DROP TABLE IF EXISTS naaccr_data_points_temp;

DROP TABLE IF EXISTS condition_occurrence_temp;

DROP TABLE IF EXISTS measurement_temp;

DROP TABLE IF EXISTS episode_temp;

DROP TABLE IF EXISTS episode_event_temp;

DROP TABLE IF EXISTS procedure_occurrence_temp;

DROP TABLE IF EXISTS drug_exposure_temp;

DROP TABLE IF EXISTS fact_relationship_temp;

DROP TABLE IF EXISTS observation_period_temp;

DROP TABLE IF EXISTS ambig_schema_discrim;

DROP TABLE IF EXISTS tmp_naaccr_data_points_temp_dates;

DROP TABLE IF EXISTS tmp_concept_naaccr_procedures;


COMMIT;
