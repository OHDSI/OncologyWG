-- 10  Number of date of initial diagnosis modifier records

select 10 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(distinct measurement_id) as count_value
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_10
FROM @cdmDatabaseSchema.measurement m
WHERE m.measurement_concept_id = 734306 -- Initial Diagnosis