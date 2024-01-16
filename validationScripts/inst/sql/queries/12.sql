-- 12  Measurement_ids of date of initial diagnosis modifier records that do not reference the condition_occurrence table

SELECT m.measurement_id
FROM @cdmDatabaseSchema.measurement m
WHERE m.measurement_concept_id = 734306 
AND m.meas_event_field_concept_id <> 1147127