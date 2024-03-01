-- 12  Number of date of initial diagnosis modifier records that do not reference the condition_occurrence table

select 12 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG( measurement_id) as count_value
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_12
FROM measurement 
WHERE measurement_concept_id = 734306 
AND meas_event_field_concept_id <> 1147127
