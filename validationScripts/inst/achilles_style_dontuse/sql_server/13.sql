-- 13  Number of date of initial diagnosis modifier records that reference the same condition_occurrence record

select 13 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(measurement_id) as count_value
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_13
FROM (
    SELECT count(condition_occurrence_id) as c, condition_occurrence_id
    FROM measurement m
    INNER JOIN condition_occurrence co
    ON m.measurement_event_id = co.condition_occurrence_id
    AND measurement_concept_id =734306
    GROUP BY co.condition_occurrence_id
) co2
INNER JOIN measurement m2
ON m2.measurement_event_id = co2.condition_occurrence_id
AND m2.measurement_concept_id =734306 
AND co2.c > 1
