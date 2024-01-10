-- 1  Number of distinct persons with cancer record

select 1 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(distinct person_id) as count_value
FROM @cdmDatabaseSchema.condition_occurrence co
into @scratchDatabaseSchema@schemaDelim@tempAchillesPrefix_1
INNER JOIN (
    SELECT DISTINCT concept_id 
    FROM (
        SELECT c.concept_id
        FROM  @vocabDatabaseSchema.concept c
        INNER JOIN @vocabDatabaseSchema.concept_ancestor ca
        ON c.concept_id = ca.descendant_concept_id
        AND ca.ancestor_concept_id = 438112 -- neoplastic disease

        UNION ALL

        SELECT concept_id
        FROM @vocabDatabaseSchema.concept 
        WHERE concept_class_id = 'ICDO Condition' 
    )
) dcc
ON co.condition_concept_id = dcc.concept_id