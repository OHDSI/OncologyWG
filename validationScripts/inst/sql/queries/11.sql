-- 11  Person_ids of persons with a date of initial diagnosis modifier record

SELECT m.person_id
FROM @cdmDatabaseSchema.measurement m
WHERE m.measurement_concept_id = 734306 -- Initial Diagnosis