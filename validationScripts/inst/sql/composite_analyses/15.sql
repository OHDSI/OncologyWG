-- 15  Number of date of initial diagnosis modifier records by data source (i.e. Tumor registry, EHR)

select 15 as analysis_id,  
cast(q.measurement_type_concept_id as varchar(255)) as stratum_1,
cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(*) as count_value
FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_15 q
GROUP BY q.measurement_type_concept_id 
