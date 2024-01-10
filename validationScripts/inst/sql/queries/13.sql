-- 13  Measurement_ids of date of initial diagnosis modifier records that reference the same condition_occurrence record

SELECT m2.measurement_id
FROM (
    SELECT count(condition_occurrence_id) as c, condition_occurrence_id
    FROM @cdmDatabaseSchema.measurement m
    INNER JOIN @cdmDatabaseSchema.condition_occurrence co
    ON m.measurement_event_id = co.condition_occurrence_id
    AND m.measurement_concept_id =734306
    GROUP BY co.condition_occurrence_id
) co2
INNER JOIN @cdmDatabaseSchema.measurement m2
ON m2.measurement_event_id = co2.condition_occurrence_id
AND m2.measurement_concept_id =734306 
AND co2.c > 1
