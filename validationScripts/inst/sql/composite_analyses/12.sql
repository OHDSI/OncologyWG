-- 12  Number of poorly-formed date of inital diagnosis modifier records

select 12 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(DISTINCT measurement_id) as count_value
FROM (

    -- records not referencing condition_occurrence table
    SELECT measurement_id, 'wrong table' AS reason
    FROM measurement 
    WHERE measurement_concept_id = 734306 
    AND meas_event_field_concept_id <> 1147127

    UNION ALL

    -- condition_occurrence records with more than one "date of initial diagnosis" modifier
    SELECT measurement_id, 'multiple records' AS reason 
    FROM (
        SELECT count(condition_occurrence_id) as c, condition_occurrence_id
        FROM measurement m
        INNER JOIN condition_occurrence co
        ON m.measurement_event_id = co.condition_occurrence_id
        AND measurement_concept_id =734306
        GROUP BY co.condition_occurrence_id
    ) co2
    INNER JOIN measurement m2
    ON m2.measurement_event_id = co2.condition_occurrence_id
    AND m2.measurement_concept_id =734306 
    AND co2.c > 1

    UNION ALL
    
    -- modified condition_concept_id is neither of class ICDO Condition nor is a descendant concept of 438112 "neoplastic disease"
    SELECT measurement_id, 'wrong record type' AS reason
    FROM measurement m
    INNER JOIN condition_occurrence co
    ON m.measurement_event_id = co.condition_occurrence_id
    AND measurement_concept_id = 734306
    AND meas_event_field_concept_id <> 1147127 
    LEFT JOIN concept c
    ON c.concept_id = co.condition_concept_id
    LEFT JOIN concept_ancestor ca
    ON co.condition_concept_id = ca.descendant_concept_id
    AND ca.ancestor_concept_id = 438112 -- neoplastic disease
    WHERE (ca.ancestor_concept_id IS NULL AND c.concept_class_id <> 'ICDO Condition')
)