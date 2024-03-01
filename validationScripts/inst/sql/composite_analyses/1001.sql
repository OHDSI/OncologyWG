-- 1001  Number of poorly-formed date of initial diagnosis modifier records

select 1001 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(DISTINCT measurement_id) as count_value
FROM (
    SELECT measurement_id
    FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_12

    UNION ALL

    SELECT measurement_id
    FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_13

    UNION ALL

    SELECT measurement_id
    FROM @scratchDatabaseSchema.onc_val_date_of_initial_diagnosis_14
)