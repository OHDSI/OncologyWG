--NAACCR Item Ambiguities
SELECT  c1.concept_code   AS icdo3_site_histology_code
      , c3.concept_name   AS naaccr_item_name
      , c3.concept_code   AS naaccr_item_concept_code
      , case when c3.concept_code like '%@%' THEN split_part(c3.concept_code, '@', 2) ELSE c3.concept_code END AS naaccr_item_code_raw
      , c2.concept_name   AS schema_name
FROM concept c1 JOIN concept_relationship cr on c1.concept_id = cr.concept_id_1 and vocabulary_id='ICDO3'
                JOIN concept c2 on cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
                JOIN  ( SELECT c1.concept_id, COUNT(*)
                        FROM concept c1 JOIN concept_relationship cr ON c1.concept_id = cr.concept_id_1 and vocabulary_id='ICDO3'
                                        JOIN concept c2              ON cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
                        GROUP BY c1.concept_id
                        HAVING count(*) > 1 ) AS dupl ON c1.concept_id = dupl.concept_id
               JOIN concept_relationship cr2 ON c2.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Schema to Variable'
               JOIN concept c3 ON cr2.concept_id_2 = c3.concept_id AND c3.domain_id in('Measurement', 'Episode')
WHERE EXISTS(
SELECT 1
FROM concept_relationship cr4 JOIN concept c4 ON c1.concept_id = cr4.concept_id_1 AND cr4.relationship_id = 'ICDO to Schema' AND cr4.concept_id_2 != c2.concept_id AND cr4.concept_id_2 = c4.concept_id
                              JOIN concept_relationship cr5 ON c4.concept_id = cr5.concept_id_1 AND cr5.relationship_id = 'Schema to Variable'
                              JOIN concept c5 ON cr5.concept_id_2 = c5.concept_id AND case when c3.concept_code like '%@%' THEN split_part(c3.concept_code, '@', 2) ELSE c3.concept_code END = case when c5.concept_code like '%@%' THEN split_part(c5.concept_code, '@', 2) ELSE c5.concept_code END
WHERE c3.concept_name != c5.concept_name
)
--AND (split_part(c3.concept_code, '@', 2)  = '2880' OR c3.concept_code = '2880')
--AND c1.concept_code = '8000/0-C24.0'
ORDER BY c1.concept_code, case when c3.concept_code like '%@%' THEN split_part(c3.concept_code, '@', 2) ELSE c3.concept_code END, c2.concept_name