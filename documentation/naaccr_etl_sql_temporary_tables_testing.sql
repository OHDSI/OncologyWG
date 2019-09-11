SET search_path TO omop, public;

SELECT *
FROM naaccr_data_points
ORDER BY record_id

----Setp 1: Diagnosis Condition Occurrence
SET search_path TO omop, public;
--Duplicate record_ids
SELECT COUNT(*), ndp1.record_id
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number = '390' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
GROUP BY ndp1.record_id
HAVING COUNT(*) > 1;

--Missing ICDO site/histology combinations
SET search_path TO omop, public;
SELECT ndp1.histology_site
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number = '390' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
WHERE ndp1.histology_site NOT IN(
  SELECT condition_source_value
  FROM condition_occurrence
  WHERE condition_type_concept_id = 32534
)
--Expectation
SET search_path TO omop, public;
SELECT *
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number = '390' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
--WHERE ndp1.record_id = '?'
ORDER BY ndp1.record_id;

--Result
SET search_path TO omop, public;
SELECT *
FROM condition_occurrence
WHERE condition_type_concept_id = 32534;

----Steps 2,3 and 4: Diagnosis Condition Occurrence modifiers
--Diagnosis Modifiers Standard categorical
--Diagnosis Modifiers Non-standard categorical
--Diagnosis Modifiers Numeric

--Expectation
SET search_path TO omop, public;

SELECT  ni.*
      , ndp4.*
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number = '390' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('390', '400', '521') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Cancer Identification','Stage/Prognostic Factors')
AND
EXISTS(
SELECT 1
FROM concept c1
WHERE ndp4.naaccr_item_number = CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE concept_code END
AND c1.domain_id = 'Measurement'
)
AND ndp4.record_id = '?'
ORDER BY ndp1.record_id, ni.item_number

--Result
SET search_path TO omop, public;

SELECT  CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END AS item_number
      , c1.concept_name
      , c1.concept_code
      , c2.concept_code
      , c2.concept_name
      , c2.standard_concept
      , m1.value_as_concept_id
      , m1.value_as_number
      , m1.measurement_source_value
      , m1.value_source_value
FROM condition_occurrence co1 JOIN measurement m1 ON co1.condition_occurrence_id = m1.modifier_of_event_id AND m1.modifier_of_field_concept_id = 1147127
                              JOIN concept c1 ON m1.measurement_concept_id = c1.concept_id
                              LEFT JOIN concept c2 on m1.value_as_concept_id = c2.concept_id
WHERE co1.stop_reason = '?'
ORDER BY CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END

--Step 7: Copy Condition Occurrence Measurements for Disease Episode--Expectation
--Expectation
SET search_path TO omop, public;

SELECT  CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END AS item_number
      , c1.concept_name
      , c1.concept_code
      , c2.concept_code
      , c2.concept_name
      , c2.standard_concept
      , m1.value_as_concept_id
      , m1.value_as_number
      , m1.measurement_source_value
      , m1.value_source_value
FROM condition_occurrence co1 JOIN measurement m1 ON co1.condition_occurrence_id = m1.modifier_of_event_id AND m1.modifier_of_field_concept_id = 1147127 -- ‘condition_occurrence.condition_occurrence_id’ concept
                              JOIN concept c1 ON m1.measurement_concept_id = c1.concept_id
                              LEFT JOIN concept c2 on m1.value_as_concept_id = c2.concept_id
--WHERE co1.stop_reason = '?'
ORDER BY CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END

--Result
SET search_path TO omop, public;
SELECT  CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END AS item_number
      , c1.concept_name
      , c1.concept_code
      , c2.concept_code
      , c2.concept_name
      , c2.standard_concept
      , m1.value_as_concept_id
      , m1.value_as_number
      , m1.measurement_source_value
      , m1.value_source_value
FROM episode e1 JOIN episode_event ee1          ON e1.episode_id = ee1.episode_id AND e1.episode_concept_id = 32528 --Disease First Occurrence
                JOIN condition_occurrence  co1  ON ee1.event_id = co1.condition_occurrence_id AND ee1.episode_event_field_concept_id = 1147127 --condition_occurrence.condition_occurrence_id;
                JOIN measurement m1             ON e1.episode_id = m1.modifier_of_event_id AND m1.modifier_of_field_concept_id = 1000000003  -- ‘episode.episode_id’ concept
                JOIN concept c1                 ON m1.measurement_concept_id = c1.concept_id
                LEFT JOIN concept c2            on m1.value_as_concept_id = c2.concept_id
--WHERE co1.stop_reason = '?'
ORDER BY CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END;


----Setp 18 and 21: Episode and Episode Event Treatment Regimen
-- We won't balance until thse codes are fixed.
-- Ovary@1290@26
-- Ovary@1290@35
-- Ovary@1290@50
-- Ovary@1290@55

--Expectation
SET search_path TO omop, public;
SELECT  ni.item_number
      , ni.item_name
      , ni.section
      , ndp4.record_id
      , ndp4.naaccr_item_number
      , ndp4.naaccr_item_value
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number = '390' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('390', '400', '521') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Treatment-1st Course')
AND ni.item_number in(
 '1290'
,'1390'
,'1400'
,'1410'
,'1506'
,'1516'
,'1526'
)
AND ndp4.naaccr_item_value NOT IN('00','99', '98')

--Result
SET search_path TO omop, public;
select  c1.concept_name
      , c2.concept_name
      , e1.episode_concept_id
      , e1.episode_source_value
from episode e1 join concept c1 on e1.episode_concept_id = c1.concept_id
                join concept c2 on e1.episode_object_concept_id = c2.concept_id
where e1.episode_concept_id = 32531 --Treatment Regimen
--and e1.episode_number = ?;


--Step 19: Move procedure_occurrence_temp into procedure_occurrence
--Expectation
SET search_path TO omop, public;
select  c1.concept_name
      , c2.concept_name
      , e1.episode_concept_id
      , e1.episode_source_value
from episode e1 join concept c1 on e1.episode_concept_id = c1.concept_id
                join concept c2 on e1.episode_object_concept_id = c2.concept_id
where e1.episode_concept_id = 32531 --Treatment Regimen
and c2.domain_id = 'Procedure'
--and e1.episode_number = ?;

--Result
SET search_path TO omop, public;
SELECT  c1.concept_name
      , c2.concept_name
      , e1.episode_concept_id
      , e1.episode_source_value
FROM episode e1 JOIN concept c1               ON e1.episode_concept_id = c1.concept_id
                JOIN concept c2               ON e1.episode_object_concept_id = c2.concept_id
                JOIN episode_event ee1        ON e1.episode_id = ee1.episode_id
                JOIN procedure_occurrence po1 ON ee1.event_id = po1.procedure_occurrence_id AND e1.episode_object_concept_id = po1.procedure_concept_id
WHERE e1.episode_concept_id = 32531 --Treatment Regimen
AND c2.domain_id = 'Procedure'
AND po1.procedure_type_concept_id = 32534 -- ‘Tumor registry’ concept. Fix me.

--Step 20: Move drug_exposure_temp into drug_exposure
--Expectation
SET search_path TO omop, public;
select  c1.concept_name
      , c2.concept_name
      , e1.episode_concept_id
      , e1.episode_source_value
from episode e1 join concept c1 on e1.episode_concept_id = c1.concept_id
                join concept c2 on e1.episode_object_concept_id = c2.concept_id
where e1.episode_concept_id = 32531 --Treatment Regimen
and c2.domain_id = 'Regimen'
--and e1.episode_number = ?;

--Result
SET search_path TO omop, public;
SELECT  c1.concept_name
      , c2.concept_name
      , e1.episode_concept_id
      , e1.episode_source_value
FROM episode e1 JOIN concept c1               ON e1.episode_concept_id = c1.concept_id
                JOIN concept c2               ON e1.episode_object_concept_id = c2.concept_id
                JOIN episode_event ee1        ON e1.episode_id = ee1.episode_id
                JOIN drug_exposure de1        ON ee1.event_id = de1.drug_exposure_id
WHERE e1.episode_concept_id = 32531 --Treatment Regimen
AND c2.domain_id = 'Regimen'
AND de1.drug_type_concept_id = 32534 -- ‘Tumor registry’ concept. Fix me.

----Steps 13 and 14: Treatment Episode modifiers
--Treatment Episode Modifiers Standard Categorical
--Treatment Episode Modifiers Numeric

--Expectation
-- Surgery
SET search_path TO omop, public;
SELECT  ni.*
      , ndp4.*
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number ='1200' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('400', '521', '1200') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Treatment-1st Course')
AND
EXISTS(
SELECT 1
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has parent item' AND cr1.concept_id_2 = 35918593  --RX Summ--Surg Prim Site
WHERE ndp4.naaccr_item_number = CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE concept_code END
AND c1.domain_id = 'Measurement'
)
--AND ndp4.record_id = '?'
ORDER BY ndp1.record_id, ni.item_number

-- Radiation Therapy
SET search_path TO omop, public;
SELECT  ni.*
      , ndp4.*
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number ='1200' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('400', '521', '1200') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Treatment-1st Course')
AND
EXISTS(
SELECT 1
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has parent item'
AND cr1.concept_id_2 IN(35918686) --Phase I Radiation Treatment Modality
WHERE ndp4.naaccr_item_number = CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE concept_code END

AND c1.domain_id = 'Measurement'
)
--AND ndp4.record_id = '?'
ORDER BY ndp1.record_id, ni.item_number

SET search_path TO omop, public;
SELECT  ni.*
      , ndp4.*
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number ='1210' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('400', '521', '1210') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Treatment-1st Course')
AND
EXISTS(
SELECT 1
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has parent item'
AND cr1.concept_id_2 IN(35918378) --Phase II Radiation Treatment Modality
WHERE ndp4.naaccr_item_number = CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE concept_code END

AND c1.domain_id = 'Measurement'
)
--AND ndp4.record_id = '?'
ORDER BY ndp1.record_id, ni.item_number

SET search_path TO omop, public;
SELECT  ni.*
      , ndp4.*
FROM naaccr_data_points ndp1 JOIN naaccr_data_points ndp2 ON ndp1.record_id = ndp2.record_id AND ndp1.naaccr_item_number = '400' AND ndp2.naaccr_item_number = '521' AND ndp1.naaccr_item_value IS NOT NULL AND ndp2.naaccr_item_value IS NOT NULL AND ndp1.person_id IS NOT NULL AND ndp2.person_id IS NOT NULL
                             JOIN naaccr_data_points ndp3 ON ndp1.record_id = ndp3.record_id AND ndp3.naaccr_item_number ='1210' AND ndp3.naaccr_item_value IS NOT NULL AND ndp3.person_id IS NOT NULL AND CASE WHEN length(ndp3.naaccr_item_value) = 8 THEN to_date(ndp3.naaccr_item_value,'YYYYMMDD') ELSE NULL END IS NOT NULL
                             JOIN naaccr_data_points ndp4 ON ndp1.record_id = ndp4.record_id AND ndp4.naaccr_item_number NOT IN('400', '521', '1210') AND ndp4.naaccr_item_value IS NOT NULL AND trim(ndp4.naaccr_item_value) != '' AND ndp4.person_id IS NOT NULL
                             JOIN naaccr_items ni ON ndp4.naaccr_item_number = ni.item_number
WHERE ni.section IN('Treatment-1st Course')
AND
EXISTS(
SELECT 1
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Has parent item'
AND cr1.concept_id_2 IN(35918255) --Phase III Radiation Treatment Modality
WHERE ndp4.naaccr_item_number = c1.concept_code
AND c1.domain_id = 'Measurement'
)
--AND ndp4.record_id = '?'
ORDER BY ndp1.record_id, ni.item_number

--Result
SET search_path TO omop, public;

SELECT  e1.episode_number
      , CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END AS item_number
      , c1.concept_name
      , c1.concept_code
      , c2.concept_code
      , c2.concept_name
      , c2.standard_concept
      , m1.value_as_concept_id
      , m1.value_as_number
      , m1.measurement_source_value
      , m1.value_source_value
FROM episode e1 JOIN measurement m1 ON e1.episode_id = m1.modifier_of_event_id AND m1.modifier_of_field_concept_id = 1000000003 -- ‘episode.episode_id’ concept
                JOIN concept c1 ON m1.measurement_concept_id = c1.concept_id
                LEFT JOIN concept c2 on m1.value_as_concept_id = c2.concept_id
WHERE  e1.episode_concept_id = 32531 --Treatment Regimen
--AND --e1.episode_number = '?'
ORDER BY e1.episode_number, CASE WHEN c1.concept_code like '%@%' THEN split_part(c1.concept_code, '@', 2) ELSE c1.concept_code END