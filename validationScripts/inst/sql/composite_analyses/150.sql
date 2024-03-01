-- 150  Number of date of initial diagnosis modifier records that come from tumor registry data source

select 150 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(*) as count_value
FROM @resultsDatabaseSchema.onc_validation_results
WHERE analysis_id = 15
AND stratum_1 = 32879
