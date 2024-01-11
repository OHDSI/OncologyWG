-- 15  Measurement_ids, measurement_type_concept_ids, and measurement_type_concept_names of date of initial diagnosis modifier records

SELECT m.measurement_id
     , m.measurement_type_concept_id
     , c.concept_name AS measurement_type_concept_name
FROM @cdmDatabaseSchema.measurement m
INNER JOIN @vocabDatabaseSchema.concept c
ON m.measurement_type_concept_id = c.concept_id
AND measurement_concept_id = 734306 