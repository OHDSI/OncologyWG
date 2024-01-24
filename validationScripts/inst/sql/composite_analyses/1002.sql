-- 1002  Proportion of poorly-formed date of initial diagnosis modifier records

select 1002 as analysis_id,
CASE WHEN num_cancer_diagnoses != 0 THEN
    cast(cast(1.0*num_poorly_formed as float)/CAST(num_cancer_diagnoses as float) as varchar(255)) 
ELSE 
    cast(null as varchar(255)) END as stratum_1,
cast(num_poorly_formed as varchar(255)) as stratum_2,
cast(num_cancer_diagnoses as varchar(255)) as stratum_3,
cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
sign(num_poorly_formed) as count_value
FROM (
    SELECT (
        SELECT count_value
        FROM @resultsDatabaseSchema.onc_validation_results
        WHERE analysis_id = 1001
    ) AS num_poorly_formed, (
        SELECT count_value
        FROM @resultsDatabaseSchema.onc_validation_results
        WHERE analysis_id = 2
    ) AS num_cancer_diagnoses
)