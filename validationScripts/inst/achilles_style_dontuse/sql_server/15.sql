-- 15  Number of date of initial diagnosis modifier records by measurement_type_concept_id

select 15 as analysis_id,  
cast(measurement_type_concept_id as varchar(255)) as stratum_1,
cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(measurement_id) as count_value
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_15
FROM measurement
WHERE measurement_concept_id = 734306 
GROUP BY measurement_type_concept_id