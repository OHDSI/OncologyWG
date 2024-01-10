-- 11  Number of persons with a date of initial diagnosis modifier record

select 11 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(distinct person_id) as count_value
FROM @cdmDatabaseSchema.measurement m
WHERE m.measurement_concept_id = 734306 -- Initial Diagnosis