-- 13  Number of invalid dates associated with date of initial diagnosis modifier records

SELECT count(measurement_id)
FROM (
    SELECT m.measurement_id
        , CASE WHEN p.birth_datetime > m.measurement_datetime THEN 1
                WHEN d.death_datetime < m.measurement_datetime THEN 1
                ELSE 0 END AS invalid_measurement_datetime
    FROM measurement m
    INNER JOIN person p
    ON m.person_id=p.person_id
    AND measurement_concept_id = 734306 
    LEFT JOIN death d
    ON m.person_id=d.person_id
)
WHERE invalid_measurement_datetime > 0