-- 14  Measurement_ids of invalid dates associated with date of initial diagnosis modifier records

SELECT m.measurement_id
FROM (
    SELECT m.measurement_id
        , CASE WHEN p.birth_datetime > m.measurement_datetime THEN 1
                WHEN d.death_datetime < m.measurement_datetime THEN 1
                ELSE 0 END AS invalid_measurement_datetime
    FROM @cdmDatabaseSchema.measurement m
    INNER JOIN @cdmDatabaseSchema.person p
    ON m.person_id=p.person_id
    AND measurement_concept_id = 734306 
    LEFT JOIN @cdmDatabaseSchema.death d
    ON m.person_id=d.person_id
)
WHERE invalid_measurement_datetime > 0