-- 13  Number of date of initial diagnosis modifier records that reference the same condition_occurrence record

select 13 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(*) as count_value
FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_13



-- 13  Number of invalid dates associated with date of initial diagnosis modifier records

-- SELECT count(measurement_id)
-- FROM (
--     SELECT m.measurement_id
--         , CASE WHEN p.birth_datetime > m.measurement_datetime THEN 1
--                 WHEN d.death_datetime < m.measurement_datetime THEN 1
--                 ELSE 0 END AS invalid_measurement_datetime
--     FROM measurement m
--     INNER JOIN person p
--     ON m.person_id=p.person_id
--     AND measurement_concept_id = 734306 
--     LEFT JOIN death d
--     ON m.person_id=d.person_id
-- )
-- WHERE invalid_measurement_datetime > 0