-- 10  Measurement_ids of date of initial diagnosis modifier records

SELECT m.measurement_id
FROM @cdmDatabaseSchema.measurement m
WHERE m.measurement_concept_id = 734306 -- Initial Diagnosis