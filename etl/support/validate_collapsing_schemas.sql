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
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to'
                JOIN concept c2               ON cr1.concept_id_2 = c2.concept_id
WHERE ndp4.naaccr_item_number = CASE WHEN c1.concept_code like '%@%' THEN SUBSTRING(c1.concept_code, POSITION('@' in c1.concept_code)+1, 10) ELSE c1.concept_code END
AND c1.domain_id = 'Measurement'
AND
  (
    c1.standard_concept = 'S'
    OR
    c2.standard_concept = 'S'
  )
)
AND NOT EXISTS(
SELECT 1
FROM (
SELECT  CASE WHEN c1.concept_code like '%@%' THEN SUBSTRING(c1.concept_code, POSITION('@' in c1.concept_code)+1, 10) ELSE c1.concept_code END AS item_number
      , CASE WHEN c3.concept_code like '%@%' THEN SUBSTRING(c3.concept_code, POSITION('@' in c3.concept_code)+1, 10) ELSE c3.concept_code END AS item_number_non_standard
	    , c1.concept_name
      , c1.concept_code
      , c2.concept_code
      , c2.concept_name
      , c2.standard_concept
      , m1.value_as_concept_id
      , m1.value_as_number
      , m1.measurement_source_value
      , m1.value_source_value
      , co1.stop_reason             AS record_id
FROM condition_occurrence co1 JOIN measurement m1 ON co1.condition_occurrence_id = m1.modifier_of_event_id AND m1.modifier_of_field_concept_id = 1147127
                              JOIN concept c1 ON m1.measurement_concept_id = c1.concept_id
                              LEFT JOIN concept c2 on m1.value_as_concept_id = c2.concept_id
	                            JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_2 And cr1.relationship_id = 'Maps to'
	                            JOIN concept c3 ON cr1.concept_id_1 = c3.concept_id
) data
WHERE ndp4.record_id = data.record_id
AND (
	  ndp4.naaccr_item_number = data.item_number
	  OR
	  ndp4.naaccr_item_number = data.item_number_non_standard
	)
)
ORDER BY ndp1.record_id, ni.item_number
