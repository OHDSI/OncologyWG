-- select  c1.concept_name
--       , c1.domain_id
--       , c1.standard_concept
--       , c1.concept_code
--       , c2.concept_name
--       , c2.concept_code
--       , c2.domain_id
--       , c2.standard_concept
--       , measurement_temp.*
-- from measurement_temp JOIN concept c1 on measurement_temp.measurement_concept_id = c1.concept_id
--                       JOIN concept c2 on measurement_temp.value_as_concept_Id = c2.concept_id
-- where record_id = '?'
-- --and c1.concept_code = '?'
-- order by c1.concept_name


SET search_path TO omop, public;

DELETE FROM condition_occurrence
WHERE condition_type_concept_id = 32534;

DELETE FROM measurement
WHERE measurement_type_concept_id = 32534;

UPDATE naaccr_data_points
SET histology_site =  overlay(histology placing substring(histology, 4, 1) || '/' from 4 for 1)  || '-' || overlay(site placing substring(site, 3,1) || '.' from 3 for 1);


UPDATE naaccr_data_points
SET person_id = pii_mrn.person_id
FROM pii_mrn
WHERE naaccr_data_points.medical_record_number = pii_mrn.mrn;

--Setp 1: Diagnosis

DROP TABLE IF EXISTS condition_occurrence_temp;

CREATE TEMPORARY TABLE condition_occurrence_temp
(
  condition_occurrence_id        BIGINT        NOT NULL ,
  person_id                     BIGINT        NOT NULL ,
  condition_concept_id          BIGINT        NOT NULL ,
  condition_start_date          DATE          NOT NULL ,
  condition_start_datetime      TIMESTAMP     NULL ,
  condition_end_date            DATE          NULL ,
  condition_end_datetime        TIMESTAMP     NULL ,
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
SELECT (( SELECT MAX(condition_occurrence_id) FROM condition_occurrence) + row_number() over())                AS condition_occurrence_id
      , s.person_id                                                                                           AS person_id
      , c2.concept_id                                                                                         AS condition_concept_id
      , CASE WHEN length(s.naaccr_item_value) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END  AS condition_start_date
      , CASE WHEN length(s.naaccr_item_value) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END  AS condition_start_datetime
      , NULL                                                                                                  AS condition_end_date
      , NULL                                                                                                  AS condition_end_datetime
      , 32534                                                                                                 AS condition_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                  AS stop_reason
      , NULL                                                                                                  AS provider_id
      , NULL                                                                                                  AS visit_occurrence_id
--    , NULL                                                                                                  AS visit_detail_id
      , s.histology_site                                                                                      AS condition_source_value
      , c1.concept_id                                                                                         AS condition_source_concept_id
      , NULL                                                                                                  AS condition_status_source_value
      , NULL                                                                                                  AS condition_status_concept_id
      , s.record_id                                                                                           AS record_id
FROM naaccr_data_points AS s JOIN concept AS c2              ON c2.standard_concept = 'S'
                             JOIN concept_relationship AS ra ON ra.concept_id_2 = c2.concept_id AND ra.relationship_id = 'Maps to'
                             JOIN concept as c1              ON c1.concept_id = ra.concept_id_1  AND c1.concept_code = s.histology_site  AND c1.vocabulary_id ='ICDO3'
WHERE s.naaccr_item_number = '390'
AND CASE WHEN length(s.naaccr_item_value) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
AND s.person_id IS NOT NULL;

--
-- INSERT INTO condition_occurrence
-- (
--     condition_occurrence_id
--   , person_id
--   , condition_concept_id
--   , condition_start_date
--   , condition_start_datetime
--   , condition_end_date
--   , condition_end_datetime
--   , condition_type_concept_id
--   , stop_reason
--   , provider_id
--   , visit_occurrence_id
-- --, visit_detail_id
--   , condition_source_value
--   , condition_source_concept_id
--   , condition_status_source_value
--   , condition_status_concept_id
-- )
-- SELECT  condition_occurrence_id
--       , person_id
--       , condition_concept_id
--       , condition_start_date
--       , condition_start_datetime
--       , condition_end_date
--       , condition_end_datetime
--       , condition_type_concept_id
--       , stop_reason
--       , provider_id
--       , visit_occurrence_id
--       --, visit_detail_id
--       , condition_source_value
--       , condition_source_concept_id
--       , condition_status_source_value
--       , condition_status_concept_id
-- FROM condition_occurrence_temp;

--Step 2: Diagnosis Modifiers Standard categorical

DROP TABLE IF EXISTS measurement_temp;

CREATE TEMPORARY TABLE measurement_temp
(
  measurement_id                BIGINT       NOT NULL ,
  person_id                     BIGINT       NOT NULL ,
  measurement_concept_id        BIGINT       NOT NULL ,
  measurement_date              DATE         NOT NULL ,
  measurement_time              VARCHAR(10)  NULL ,
  measurement_datetime          TIMESTAMP    NULL ,
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , cot.condition_start_date                                                                                                                                AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                                                                    AS operator_concept_id
      , NULL                                                                                                                                                    AS value_as_number
      , c3.concept_id                                                                                                                                           AS value_as_concept_id
      , NULL                                                                                                                                                    AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , c2.concept_code                                                                                                                                         AS measurement_source_value
      , c2.concept_id                                                                                                                                           AS measurement_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , c3.concept_code                                                                                                                                         AS value_source_value
      , cot.condition_occurrence_id                                                                                                                             AS modifier_of_event_id
      , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept AS c2                ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                              -- Identify numeric type variables
                             LEFT JOIN concept_relationship cn ON c2.concept_id = cn.concept_id_1 and cn.relationship_id = 'Has type' and cn.concept_id_2 = 32676 --'Numeric'
                              ---- Getting permissible value
                             JOIN concept AS c3                ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value) AND  c3.domain_id = 'Meas Value' AND c3.standard_concept = 'S'
                              ---- Getting condition_occurrence record
                             JOIN condition_occurrence_temp cot ON s.record_id = cot.record_id
WHERE cn.concept_id_1 IS NULL -- excluding numeric types
AND s.person_id IS NOT NULL
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918588' --Primary Site
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918916' --Histology
);

--Step  3: Diagnosis Modifiers Non-standard categorical
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c4.concept_id                                                                                                                                           AS measurement_concept_id
      , cot.condition_start_date                                                                                                                                AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                                                                    AS operator_concept_id
      , NULL                                                                                                                                                    AS value_as_number
      , c3.concept_id                                                                                                                                           AS value_as_concept_id
      , NULL                                                                                                                                                    AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , c4.concept_code                                                                                                                                         AS measurement_source_value
      , c4.concept_id                                                                                                                                           AS measurement_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , c4.concept_code                                                                                                                                         AS value_source_value
      , cot.condition_occurrence_id                                                                                                                             AS modifier_of_event_id
      , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                              JOIN concept AS c2                ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept IS NULL
                              JOIN concept_relationship cr2     ON c2.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Maps to'
                              JOIN concept c4                   ON cr2.concept_id_2 = c4.concept_id AND c4.vocabulary_id = 'NAACCR' AND c4.standard_concept = 'S'
                              -- Identify numeric type variables
                              LEFT JOIN concept_relationship cn ON c4.concept_id = cn.concept_id_1 and cn.relationship_id = 'Has type' and cn.concept_id_2 = 32676 --'Numeric'
                              ---- Getting permissible value
                              JOIN concept AS c3                ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = c4.concept_code ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || c4.concept_code  || '@'  || s.naaccr_item_value) AND  c3.domain_id = 'Meas Value' AND c3.standard_concept = 'S'
                              ---- Getting condition_occurrence record
                              JOIN condition_occurrence_temp cot ON s.record_id = cot.record_id
WHERE cn.concept_id_1 IS NULL -- excluding numeric types
AND s.person_id IS NOT NULL
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c4.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918588' --Primary Site
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c4.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918916' --Histology
);

--Step 4: Diagnosis Modifiers Numeric
DROP TABLE IF EXISTS concept_temp;

CREATE TEMPORARY TABLE concept_temp (
  concept_id          BIGINT        NOT NULL ,
  concept_name        VARCHAR(255)  NOT NULL ,
  domain_id            VARCHAR(20)    NOT NULL ,
  vocabulary_id        VARCHAR(20)    NOT NULL ,
  concept_class_id    VARCHAR(20)    NOT NULL ,
  standard_concept    VARCHAR(1)    NULL ,
  concept_code        VARCHAR(50)    NOT NULL ,
  valid_start_date    DATE          NOT NULL ,
  valid_end_date      DATE          NOT NULL ,
  invalid_reason      VARCHAR(1)    NULL
)
;

INSERT INTO concept_temp
(  concept_id
      , concept_name
      , domain_id
      , vocabulary_id
      , concept_class_id
      , standard_concept
      , concept_code
      , valid_start_date
      , valid_end_date
      , invalid_reason
)
SELECT  c1.concept_id
      , c1.concept_name
      , c1.domain_id
      , c1.vocabulary_id
      , c1.concept_class_id
      , c1.standard_concept
      , c1.concept_code
      , c1.valid_start_date
      , c1.valid_end_date
      , c1.invalid_reason
FROM concept c1   JOIN concept_relationship crn ON c1.concept_id = crn.concept_id_1 and crn.relationship_id = 'Has type' and crn.concept_id_2 = 32676 --'Numeric'
;


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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , cot.condition_start_date                                                                                                                                AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , cot.condition_start_datetime                                                                                                                            AS measurement_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , CASE WHEN c3.concept_id IS NULL THEN NULL ELSE cn.operator_concept_id END                                                                               AS operator_concept_id
      , CASE WHEN c3.concept_id IS NULL THEN CAST(s.naaccr_item_value AS float) ELSE cn.value_as_number END                                                     AS value_as_number
      , c3.concept_id                                                                                                                                           AS value_as_concept_id
      , CASE WHEN c3.concept_id IS NULL THEN cru.concept_id_2 ELSE cn.unit_concept_id END                                                                       AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , c2.concept_code                                                                                                                                         AS measurement_source_value
      , c2.concept_id                                                                                                                                           AS measurement_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , c3.concept_code                                                                                                                                         AS value_source_value
      , cot.condition_occurrence_id                                                                                                                             AS modifier_of_event_id
      , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘condition_occurrence.condition_occurrence_id’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                             ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept_temp AS c2                         ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                             -- Getting units if exist
                             LEFT JOIN concept_relationship AS cru      ON c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
                             -- Getting permissible value for ranges
                             LEFT JOIN concept AS c3                    ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             LEFT JOIN concept_numeric AS cn            ON c3.concept_id = cn.concept_id
                              ---- Getting condition_occurrence record
                             JOIN condition_occurrence_temp cot         ON s.record_id = cot.record_id
WHERE s.person_id IS NOT NULL
AND s.naaccr_item_value IS NOT NULL
AND TRIM(s.naaccr_item_value) != ''
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918588' --Primary Site
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2 = '35918916' --Histology
);

UPDATE measurement_temp
SET   measurement_date = CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END
    , measurement_datetime = CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END
FROM concept_relationship crd, concept cd, naaccr_data_points sd
WHERE measurement_temp.measurement_concept_id = crd.concept_id_1
AND crd.relationship_id = 'Variable has date'
AND crd.concept_id_2 = cd.concept_id
AND sd.naaccr_item_number = cd.concept_code
AND measurement_temp.record_id = sd.record_id
AND sd.naaccr_item_value NOT IN('0', '99999999');

--
-- INSERT INTO measurement
-- (
--       measurement_id
--     , person_id
--     , measurement_concept_id
--     , measurement_date
--     , measurement_time
--     , measurement_datetime
--     , measurement_type_concept_id
--     , operator_concept_id
--     , value_as_number
--     , value_as_concept_id
--     , unit_concept_id
--     , range_low
--     , range_high
--     , provider_id
--     , visit_occurrence_id
--     , visit_detail_id
--     , measurement_source_value
--     , measurement_source_concept_id
--     , unit_source_value
--     , value_source_value
--     , modifier_of_event_id
--     , modifier_of_field_concept_id
-- )
-- SELECT
--       measurement_id
--     , person_id
--     , measurement_concept_id
--     , measurement_date
--     , measurement_time
--     , measurement_datetime
--     , measurement_type_concept_id
--     , operator_concept_id
--     , value_as_number
--     , value_as_concept_id
--     , unit_concept_id
--     , range_low
--     , range_high
--     , provider_id
--     , visit_occurrence_id
--     , visit_detail_id
--     , measurement_source_value
--     , measurement_source_concept_id
--     , unit_source_value
--     , value_source_value
--     , modifier_of_event_id
--     , modifier_of_field_concept_id
-- FROM measurement_temp;

--Step 5: Treatment Episodes

--moomin
SET search_path TO omop, public;

DELETE FROM condition_occurrence
WHERE condition_type_concept_id = 32534;

DELETE FROM measurement
WHERE measurement_type_concept_id = 32534;

UPDATE naaccr_data_points
SET histology_site =  overlay(histology placing substring(histology, 4, 1) || '/' from 4 for 1)  || '-' || overlay(site placing substring(site, 3,1) || '.' from 3 for 1);


UPDATE naaccr_data_points
SET person_id = pii_mrn.person_id
FROM pii_mrn
WHERE naaccr_data_points.medical_record_number = pii_mrn.mrn;


DROP TABLE IF EXISTS measurement_temp;

CREATE TEMPORARY TABLE measurement_temp
(
  measurement_id                BIGINT       NOT NULL ,
  person_id                     BIGINT       NOT NULL ,
  measurement_concept_id        BIGINT       NOT NULL ,
  measurement_date              DATE         NOT NULL ,
  measurement_time              VARCHAR(10)  NULL ,
  measurement_datetime          TIMESTAMP    NULL ,
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

--moomin

DROP TABLE IF EXISTS episode_temp;

CREATE TABLE episode_temp (
	episode_id                  BIGINT        NOT NULL,
	person_id                   BIGINT        NOT NULL,
	episode_concept_id          INTEGER       NOT NULL,
	episode_start_datetime      TIMESTAMP     NULL,       --Fix me
	episode_end_datetime        TIMESTAMP     NULL,
	episode_parent_id           BIGINT        NULL,
	episode_number              INTEGER       NULL,
	episode_object_concept_id   INTEGER       NOT NULL,
	episode_type_concept_id     INTEGER       NOT NULL,
	episode_source_value        VARCHAR(50)   NULL,
	episode_source_concept_id   INTEGER 	    NULL,
  record_id                   VARCHAR(255)  NULL
)
;

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
SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode) IS NULL THEN 0 ELSE  (SELECT MAX(episode_id) FROM episode) END + row_number() over())                 AS episode_id
      , s.person_id                                                                                                                                             AS person_id
      , c4.concept_id                                                                                                                                           AS episode_concept_id
      , CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END                                                  AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , c3.concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , s.naaccr_item_number || '@' || s.naaccr_item_value                                                                                                      AS episode_source_value
      , c3.concept_id                                                                                                                                           AS episode_source_concept_id
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
--                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Proc Schema'

                             JOIN concept AS c1                ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept AS c2                ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Episode' AND c2.standard_concept IS NULL
                             JOIN concept_relationship cr2     ON c2.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Maps to'
                             JOIN concept AS c4                ON cr2.concept_id_2 = c4.concept_id
                              -- Getting permissible value
                             JOIN concept AS c3                ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_name || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value) AND c3.standard_concept = 'S' --AND c3.domain_id = 'Meas Value'
                             --                               ---- Getting permissible value

                             JOIN concept_relationship cr3     ON c2.concept_id = cr3.concept_id_1 AND cr3.relationship_id = 'Variable has date'
                             JOIN concept c5                   ON cr3.concept_id_2 = c5.concept_id
                             JOIN naaccr_data_points sd        ON s.record_id = sd.record_id AND c5.concept_code = sd.naaccr_item_number AND sd.naaccr_item_value NOT IN('99999999', '0') AND (sd.naaccr_item_number ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$');

--Step 6: Treatment Episode Modifiers Standard Categorical
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , et.episode_start_datetime                                                                                                                               AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , et.episode_start_datetime                                                                                                                               AS measurement_datetime
      , 32534                                                                                                                                                   AS measurement_type_concept_id -- ‘Tumor registry’ concept
      , NULL                                                                                                                                                    AS operator_concept_id
      , NULL                                                                                                                                                    AS value_as_number
      , c3.concept_id                                                                                                                                           AS value_as_concept_id
      , NULL                                                                                                                                                    AS unit_concept_id
      , NULL                                                                                                                                                    AS range_low
      , NULL                                                                                                                                                    AS range_high
      , NULL                                                                                                                                                    AS provider_id
      , NULL                                                                                                                                                    AS visit_occurrence_id
      , NULL                                                                                                                                                    AS visit_detail_id
      , c2.concept_code                                                                                                                                         AS measurement_source_value
      , c2.concept_id                                                                                                                                           AS measurement_source_concept_id
      , NULL                                                                                                                                                    AS unit_source_value
      , c3.concept_code                                                                                                                                         AS value_source_value
      , et.episode_id                                                                                                                                           AS modifier_of_event_id
      , 1147127                                                                                                                                                 AS modifier_field_concept_id -- ‘episode.episode_id’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept AS c2                ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                              -- Identify numeric type variables
                             LEFT JOIN concept_relationship cn ON c2.concept_id = cn.concept_id_1 and cn.relationship_id = 'Has type' and cn.concept_id_2 = 32676 --'Numeric'
                              ---- Getting permissible value
                             JOIN concept AS c3                ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value) AND  c3.domain_id = 'Meas Value' AND c3.standard_concept = 'S'
                              ---- Getting episode record
                             JOIN episode_temp et             ON s.record_id = et.record_id
WHERE cn.concept_id_1 IS NULL -- excluding numeric types
AND s.person_id IS NOT NULL
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
      35918834  --
    , 35918894  --RX Date Radiation
    , 35918372  --RX Date Rad Ended
  )
);