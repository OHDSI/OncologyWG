-- 11  Number of persons with a date of initial diagnosis modifier record

select 11 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(*) as count_value
FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_11
