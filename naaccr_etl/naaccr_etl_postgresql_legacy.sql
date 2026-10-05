SET search_path TO omop, public;
BEGIN TRANSACTION;
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

create or replace function is_date(s varchar) returns boolean as $$
begin
  perform s::date;
  return true;
exception when others then
  return false;
end;
$$ language plpgsql;

UPDATE naaccr_data_points
SET naaccr_item_value = NULL
WHERE naaccr_item_number IN(
   '390'
, '1200'
, '1210'
, '1220'
, '1230'
, '1240'
)
AND (
  length(naaccr_item_value) != 8
or
  is_date(naaccr_item_value) = false
);

--Setp 1: Diagnosis Condition Occurrence

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

DELETE FROM concept_temp;

--Restrict to schemas that do not have ICDO overlapping site/histology combinations
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
SELECT  c3.concept_id
      , c3.concept_name
      , c3.domain_id
      , c3.vocabulary_id
      , c3.concept_class_id
      , c3.standard_concept
      , c3.concept_code
      , c3.valid_start_date
      , c3.valid_end_date
      , c3.invalid_reason
FROM concept c3
WHERE c3.concept_id IN(
  SELECT  c2.concept_id as schema_concept_id
  FROM concept c1 JOIN concept_relationship cr ON c1.concept_id = cr.concept_id_1 AND vocabulary_id='ICDO3'
                  JOIN concept c2              ON cr.concept_id_2 = c2.concept_id AND relationship_id = 'ICDO to Schema'
                  JOIN (
                          SELECT  c1.concept_id
                                , c1.concept_code
                                , count(*) as total
                          FROM concept c1 JOIN concept_relationship cr ON c1.concept_id = cr.concept_id_1 AND c1.vocabulary_id='ICDO3'
                                          JOIN concept c2              ON cr.concept_id_2 = c2.concept_id AND relationship_id = 'ICDO to Schema'
                          GROUP BY c1.concept_id, c1.concept_code
                          HAVING count(*) = 1
                      ) as dupl ON c1.concept_id = dupl.concept_id
  GROUP BY c2.concept_id
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
SELECT ( CASE WHEN  (SELECT MAX(condition_occurrence_id) FROM condition_occurrence) IS NULL THEN 0 ELSE  (SELECT MAX(condition_occurrence_id) FROM condition_occurrence) END + row_number() over()) AS condition_occurrence_id
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
      , d.concept_id                                                                                          AS condition_source_concept_id
      , NULL                                                                                                  AS condition_status_source_value
      , NULL                                                                                                  AS condition_status_concept_id
      , s.record_id                                                                                           AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept c1                   ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                             JOIN concept_temp                 ON c1.concept_id = concept_temp.concept_id
                             JOIN concept_relationship    ra   ON ra.concept_id_1 = d.concept_id AND ra.relationship_id = 'Maps to'
                             JOIN concept  c2                  ON c2.standard_concept = 'S' AND ra.concept_id_2 = c2.concept_id
WHERE s.naaccr_item_number = '390'
AND s.naaccr_item_value IS NOT NULL
AND s.person_id IS NOT NULL;


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
FROM condition_occurrence_temp;

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
--      , c3.concept_code                                                                                                                                         AS value_source_value
--MGURLEY 12/2/2019 Change to match revised ETL.
      , s.naaccr_item_value                                                                                                                                     AS value_source_value

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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
DELETE FROM concept_temp;

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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
                             JOIN concept_temp AS c2                    ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
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
AND
(
  (
    c3.concept_id IS NULL
    AND
    (
      s.naaccr_item_value IS NOT NULL
      OR
      cn.value_as_number  IS NOT NULL
    )
  )
  OR
  (
    c3.concept_id IS NOT NULL
    AND
    c3.standard_concept = 'S'
  )
)
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

--Step 5: Disease Episodes
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
  episode_source_concept_id   INTEGER       NULL,
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

--Step 6: Connect Condition Occurrence to Disease Episodes in Episode Event
DROP TABLE IF EXISTS episode_event_temp;
CREATE TABLE episode_event_temp (
  episode_id                      BIGINT   NOT NULL,
  event_id                         BIGINT   NOT NULL,
  episode_event_field_concept_id  INTEGER NOT NULL
);

INSERT INTO episode_event_temp
(
    episode_id
  , event_id
  , episode_event_field_concept_id

)
SELECT  et.episode_id                     AS episode_id
      , cot.condition_occurrence_id       AS event_id
      , 1147127                           AS episode_event_field_concept_id --condition_occurrence.condition_occurrence_id
FROM condition_occurrence_temp cot JOIN episode_temp et ON cot.record_id = et.record_id;

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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
FROM measurement_temp mt JOIN episode_temp et ON mt.record_id = et.record_id;

--Step 8: Treatment Episodes
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

DELETE FROM concept_temp;

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
FROM concept c1
WHERE EXISTS(
SELECT 1
FROM concept_relationship crn JOIN concept c2 ON crn.concept_id_1 = c2.concept_id AND crn.relationship_id = 'Variable has date' AND c2.vocabulary_id = 'NAACCR'
WHERE c1.concept_id = crn.concept_id_2
)
AND c1.concept_code IN('1200', '1210', '1220', '1230', '1240');
-- 1200=RX DATE SURGERY
-- 1210=RX DATE RADIATION
-- 1220=RX DATE CHEMO
-- 1230=RX DATE HORMONE
-- 1240=RX DATE BRM

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
SELECT ( CASE WHEN  (SELECT MAX(episode_id) FROM episode_temp) IS NULL THEN 0 ELSE  (SELECT MAX(episode_id) FROM episode_temp) END + row_number() over())                 AS episode_id
      , s.person_id                                                                                                                                             AS person_id
      , c4.concept_id                                                                                                                                           AS episode_concept_id
      , CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END                                                  AS episode_start_datetime        --?
      , NULL                                                                                                                                                    AS episode_end_datetime          --?
      , NULL                                                                                                                                                    AS episode_parent_id
      , NULL                                                                                                                                                    AS episode_number
      , c3.concept_id                                                                                                                                           AS episode_object_concept_id
      , 32546                                                                                                                                                   AS episode_type_concept_id --Episode derived from registry
      , s.naaccr_item_number || '@' || s.naaccr_item_value                                                                                                      AS episode_source_value
      , c2.concept_id                                                                                                                                           AS episode_source_concept_id
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                    ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             --JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept_relationship cr1     ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Proc Schema'

                             JOIN concept AS c1                ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept AS c2                ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Episode' AND c2.standard_concept IS NULL
                             JOIN concept_relationship cr2     ON c2.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Maps to'
                             JOIN concept AS c4                ON cr2.concept_id_2 = c4.concept_id
                              -- Getting permissible value
                             JOIN concept AS c3                ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             --                               ---- Getting permissible value

                             JOIN concept_relationship cr3     ON c2.concept_id = cr3.concept_id_1 AND cr3.relationship_id = 'Variable has date'
                             -- JOIN concept c5                   ON cr3.concept_id_2 = c5.concept_id
                             JOIN concept_temp c5              ON cr3.concept_id_2 = c5.concept_id
                             JOIN naaccr_data_points sd        ON s.record_id = sd.record_id AND sd.person_id IS NOT NULL AND c5.concept_code = sd.naaccr_item_number AND sd.naaccr_item_value NOT IN('99999999', '0') AND (sd.naaccr_item_number ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$')
WHERE s.person_id IS NOT NULL
AND
(
  (
    c3.domain_id  = 'Procedure'
  AND
    c3.standard_concept = 'S'
  )
  OR
  (
    c3.domain_id = 'Drug'
  AND
    c3.standard_concept IS NULL
  )
);

 --Step 9: Treatment Procedure Occurrence
 DROP TABLE IF EXISTS procedure_occurrence_temp;

 CREATE TABLE procedure_occurrence_temp
 (
  procedure_occurrence_id     BIGINT        NOT NULL ,
  person_id                    BIGINT        NOT NULL ,
  procedure_concept_id        BIGINT        NOT NULL ,
  procedure_date              DATE          NOT NULL ,
  procedure_datetime          TIMESTAMP     NULL ,
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
SELECT ( CASE WHEN  (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence) IS NULL THEN 0 ELSE  (SELECT MAX(procedure_occurrence_id) FROM procedure_occurrence) END + row_number() over())  AS procedure_occurrence_id
    , et.person_id                                                                                                                                                                                   AS person_id
    , et.episode_object_concept_id                                                                                                                                                                   AS procedure_concept_id
    , et.episode_start_datetime::date                                                                                                                                                                AS procedure_date
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
FROM episode_temp et JOIN concept c1 ON et.episode_object_concept_id = c1.concept_id AND c1.standard_concept = 'S' AND c1.domain_id = 'Procedure';

--Step 10: Connect Procedure Occurrence to Treatment Episodes in Episode Event
INSERT INTO episode_event_temp
(
    episode_id
  , event_id
  , episode_event_field_concept_id

)
SELECT  et.episode_id                     AS episode_id
      , pet.procedure_occurrence_id       AS event_id
      , 1147082                           AS episode_event_field_concept_id --procedure_occurrence.procedure_occurrence_id
FROM procedure_occurrence_temp pet JOIN episode_temp et ON pet.record_id = et.record_id AND pet.procedure_concept_id = et.episode_object_concept_id;

--Step 11: Treatment Drug Exposure
DROP TABLE IF EXISTS drug_exposure_temp;

CREATE TABLE drug_exposure_temp
(
  drug_exposure_id              BIGINT        NOT NULL ,
  person_id                     BIGINT        NOT NULL ,
  drug_concept_id               BIGINT        NOT NULL ,
  drug_exposure_start_date      DATE          NOT NULL ,
  drug_exposure_start_datetime  TIMESTAMP      NULL ,
  drug_exposure_end_date        DATE          NULL ,
  drug_exposure_end_datetime    TIMESTAMP      NULL ,
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
;
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
SELECT ( CASE WHEN  (SELECT MAX(drug_exposure_id) FROM drug_exposure) IS NULL THEN 0 ELSE  (SELECT MAX(drug_exposure_id) FROM drug_exposure) END + row_number() over())                             AS drug_exposure_id
    , et.person_id                                                                                                                                                                                  AS person_id
    , et.episode_object_concept_id                                                                                                                                                                  AS drug_concept_id
    , et.episode_start_datetime::date                                                                                                                                                               AS drug_exposure_start_date
    , et.episode_start_datetime                                                                                                                                                                     AS drug_exposure_start_datetime
    , et.episode_start_datetime::date                                                                                                                                                               AS drug_exposure_end_date
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
FROM episode_temp et JOIN concept c1 ON et.episode_object_concept_id = c1.concept_id AND c1.standard_concept IS NULL AND c1.domain_id = 'Drug';

--Step 12: Connect Drug Exposure to Treatment Episodes in Episode Event
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

--Step 13: Treatment Episode Modifiers Standard Categorical
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’ concept
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
AND et.episode_source_concept_id IN(
  35918686  --Phase I Radiation Treatment Modality
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
      35918686  --Phase I Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’ concept
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
AND et.episode_source_concept_id IN(
   35918378  --Phase II Radiation Treatment Modality
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918378  --Phase II Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’ concept
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
AND et.episode_source_concept_id IN(
   35918255  --Phase III Radiation Treatment Modality
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918255  --Phase III Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’ concept
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
AND et.episode_source_concept_id IN(
  35918593  --RX Summ--Surg Prim Site
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918593  --RX Summ--Surg Prim Site
  )
);

--Step 14: Treatment Episode Modifiers Numeric
DELETE FROM concept_temp;

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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , et.episode_start_datetime::date                                                                                                                         AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , et.episode_start_datetime                                                                                                                               AS measurement_datetime
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
      , et.episode_id                                                                                                                                           AS modifier_of_event_id
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                             ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept_temp AS c2                    ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                             -- Getting units if exist
                             LEFT JOIN concept_relationship AS cru      ON c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
                             -- Getting permissible value for ranges
                             LEFT JOIN concept AS c3                    ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             LEFT JOIN concept_numeric AS cn            ON c3.concept_id = cn.concept_id
                              ---- Getting episode record
                             JOIN episode_temp et                       ON s.record_id = et.record_id
WHERE s.person_id IS NOT NULL
AND s.naaccr_item_value IS NOT NULL
AND TRIM(s.naaccr_item_value) != ''
AND
(
 (
   c3.concept_id IS NULL
   AND
   (
     s.naaccr_item_value IS NOT NULL
     OR
     cn.value_as_number  IS NOT NULL
   )
 )
 OR
 (
   c3.concept_id IS NOT NULL
   AND
   c3.standard_concept = 'S'
 )
)

AND et.episode_source_concept_id IN(
  35918686  --Phase I Radiation Treatment Modality
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918686  --Phase I Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , et.episode_start_datetime::date                                                                                                                         AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , et.episode_start_datetime                                                                                                                               AS measurement_datetime
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
      , et.episode_id                                                                                                                                           AS modifier_of_event_id
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                             ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept_temp AS c2                    ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                             -- Getting units if exist
                             LEFT JOIN concept_relationship AS cru      ON c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
                             -- Getting permissible value for ranges
                             LEFT JOIN concept AS c3                    ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             LEFT JOIN concept_numeric AS cn            ON c3.concept_id = cn.concept_id
                              ---- Getting episode record
                             JOIN episode_temp et                       ON s.record_id = et.record_id
WHERE s.person_id IS NOT NULL
AND s.naaccr_item_value IS NOT NULL
AND TRIM(s.naaccr_item_value) != ''
AND
(
 (
   c3.concept_id IS NULL
   AND
   (
     s.naaccr_item_value IS NOT NULL
     OR
     cn.value_as_number  IS NOT NULL
   )
 )
 OR
 (
   c3.concept_id IS NOT NULL
   AND
   c3.standard_concept = 'S'
 )
)
AND et.episode_source_concept_id IN(
  35918378  --Phase II Radiation Treatment Modality
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918378  --Phase II Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , et.episode_start_datetime::date                                                                                                                         AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , et.episode_start_datetime                                                                                                                               AS measurement_datetime
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
      , et.episode_id                                                                                                                                           AS modifier_of_event_id
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                             ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept_temp AS c2                    ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                             -- Getting units if exist
                             LEFT JOIN concept_relationship AS cru      ON c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
                             -- Getting permissible value for ranges
                             LEFT JOIN concept AS c3                    ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             LEFT JOIN concept_numeric AS cn            ON c3.concept_id = cn.concept_id
                              ---- Getting episode record
                             JOIN episode_temp et                       ON s.record_id = et.record_id
WHERE s.person_id IS NOT NULL
AND s.naaccr_item_value IS NOT NULL
AND TRIM(s.naaccr_item_value) != ''
AND
(
 (
   c3.concept_id IS NULL
   AND
   (
     s.naaccr_item_value IS NOT NULL
     OR
     cn.value_as_number  IS NOT NULL
   )
 )
 OR
 (
   c3.concept_id IS NOT NULL
   AND
   c3.standard_concept = 'S'
 )
)
AND et.episode_source_concept_id IN(
  35918255  --Phase III Radiation Treatment Modality
)

AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918255  --Phase III Radiation Treatment Modality
  )
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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
      , s.person_id                                                                                                                                             AS person_id
      , c2.concept_id                                                                                                                                           AS measurement_concept_id
      , et.episode_start_datetime::date                                                                                                                         AS measurement_date
      , NULL                                                                                                                                                    AS measurement_time
      , et.episode_start_datetime                                                                                                                               AS measurement_datetime
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
      , et.episode_id                                                                                                                                           AS modifier_of_event_id
      , 1000000003                                                                                                                                              AS modifier_field_concept_id -- ‘episode.episode_id’’ concept
      , s.record_id                                                                                                                                             AS record_id
FROM naaccr_data_points AS s JOIN concept d                             ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
                             JOIN concept_relationship cr1              ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
                             JOIN concept AS c1                         ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
                              ---- Getting variables
                             JOIN concept_temp AS c2                    ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number) AND c2.domain_id = 'Measurement' AND c2.standard_concept = 'S'
                             -- Getting units if exist
                             LEFT JOIN concept_relationship AS cru      ON c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
                             -- Getting permissible value for ranges
                             LEFT JOIN concept AS c3                    ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
                             LEFT JOIN concept_numeric AS cn            ON c3.concept_id = cn.concept_id
                              ---- Getting episode record
                             JOIN episode_temp et                       ON s.record_id = et.record_id
WHERE s.person_id IS NOT NULL
AND s.naaccr_item_value IS NOT NULL
AND TRIM(s.naaccr_item_value) != ''
AND
(
 (
   c3.concept_id IS NULL
   AND
   (
     s.naaccr_item_value IS NOT NULL
     OR
     cn.value_as_number  IS NOT NULL
   )
 )
 OR
 (
   c3.concept_id IS NOT NULL
   AND
   c3.standard_concept = 'S'
 )
)
AND et.episode_source_concept_id IN(
  35918593  --RX Summ--Surg Prim Site
)
AND EXISTS(
  SELECT 1
  FROM concept_relationship cr
  WHERE c2.concept_id =  cr.concept_id_1
  AND cr.relationship_id = 'Has parent item'
  AND cr.concept_id_2  IN(
    35918593  --RX Summ--Surg Prim Site
  )
);

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
SELECT ( CASE WHEN  (SELECT MAX(measurement_id) FROM measurement_temp) IS NULL THEN 0 ELSE  (SELECT MAX(measurement_id) FROM measurement_temp) END + row_number() over()) AS measurement_id
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
FROM measurement_temp mt JOIN episode_temp et               ON mt.record_id = et.record_id AND et.episode_concept_id = 32531 --Treatment Regimen
                         JOIN procedure_occurrence_temp pet ON et.record_id = pet.record_id AND et.episode_object_concept_id = pet.procedure_concept_id;

--Step 16: Connect 'Treatment Episodes' to 'Disease Episodes' via parent_id
UPDATE episode_temp
SET episode_parent_id = det.episode_id
FROM episode_temp det
WHERE episode_temp.record_id        = det.record_id
AND episode_temp.episode_concept_id = 32531 --Treatment Regimen
AND det.episode_concept_id          = 32528; --Disease First Occurrence


-- Step 17: Drug Treatment Episodes.  Update to standard 'Regimen' concepts.
UPDATE episode_temp
SET episode_object_concept_id = 35803401 --Hemonc Chemotherapy Modality
FROM concept c1
WHERE episode_temp.episode_object_concept_id = c1.concept_id AND c1.vocabulary_id = 'NAACCR' AND c1.concept_code = '1390@01';

UPDATE episode_temp
SET episode_object_concept_id = 35803401 --Hemonc Chemotherapy Modality
FROM concept c1
WHERE  episode_temp.episode_object_concept_id = c1.concept_id AND c1.vocabulary_id = 'NAACCR' AND c1.concept_code = '1390@02';

UPDATE episode_temp
SET episode_object_concept_id = 35803401 --Hemonc Chemotherapy Modality
FROM concept c1
WHERE episode_temp.episode_object_concept_id = c1.concept_id AND c1.vocabulary_id = 'NAACCR' AND c1.concept_code = '1390@03';

UPDATE episode_temp
SET episode_object_concept_id = 35803407 --Hemonc Hormonotherapy Modality
FROM concept c1
WHERE episode_temp.episode_object_concept_id = c1.concept_id AND c1.vocabulary_id = 'NAACCR' AND c1.concept_code = '1400@01';

UPDATE episode_temp
SET episode_object_concept_id = 35803410 --Hemonc Immunotherapy Modality
FROM concept c1
WHERE episode_temp.episode_object_concept_id = c1.concept_id AND c1.vocabulary_id = 'NAACCR' AND c1.concept_code = '1410@01';

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
  , record_id::int
  , episode_object_concept_id
  , episode_type_concept_id
  , episode_source_value
  , episode_source_concept_id
FROM episode_temp;

--Step 19: Move procedure_occurrence_temp into procedure_occurrence
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
       , modifier_concept_id
       , quantity
       , provider_id
       , visit_occurrence_id
       , visit_detail_id
       , procedure_source_value
       , procedure_source_concept_id
       , modifier_source_value
FROM procedure_occurrence_temp;

--Step 20: Move drug_exposure_temp into drug_exposure
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
      , route_concept_id
      , lot_number
      , provider_id
      , visit_occurrence_id
      , visit_detail_id
      , drug_source_value
      , drug_source_concept_id
      , route_source_value
      , dose_unit_source_value
FROM drug_exposure_temp;

--Step 21: Move episode_event_temp into episode_event
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

--Step 22: Measurement Dates
UPDATE measurement_temp
SET   measurement_date = CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END
    , measurement_datetime = CASE WHEN length(sd.naaccr_item_value) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END
FROM concept_relationship crd, concept cd, naaccr_data_points sd
WHERE measurement_temp.measurement_concept_id = crd.concept_id_1
AND crd.relationship_id = 'Variable has date'
AND crd.concept_id_2 = cd.concept_id
AND sd.naaccr_item_number = cd.concept_code
AND measurement_temp.record_id = sd.record_id
AND sd.naaccr_item_value NOT IN('0', '99999999')
AND sd.naaccr_item_value IS NOT NULL
AND is_date(sd.naaccr_item_value) = true;

--Step 23: Move measurement_temp into measurement
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
COMMIT;