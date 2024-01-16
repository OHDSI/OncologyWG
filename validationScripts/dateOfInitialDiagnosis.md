# Date of Initial Diagnosis (validation Script Example)

## How many records exist

> Total count of measurement records that have the measurement_concept_id

```
SELECT count(*)
FROM <schema>.<database>.measurement m
WHERE m.measurement_concept_id = 734306
```

## How many patients have a record
 ```
SELECT count(DISTINCT person_id) 
FROM measurement 
WHERE measurement_concept_id = 734306
```



## How many records are "correct"

> NOTE: this could be broken down into 3 individual analyses, condensed later. Should it be?

> To be a correct "date of initial diagnosis record", you need:
> 1. measurement record modifies a record in condition_occurrence (i.e. meas_event_field_concept_id = 1147127)

```
-- Number of records not referencing condition_occurrence table
SELECT count(*) 
FROM measurement 
WHERE measurement_concept_id = 734306 
AND meas_event_field_concept_id <> 1147127
```
> 2. each modifier record points to a distinct condition_occurrence record (condition_occurrence.condition_occurrence_id = measurement.measurement_event_id)

```
-- Number of condition_occurrence records with more than one "date of initial diagnosis" modifier
-- TODO sum count(condition_occurrence_id) to get number of incorrect modifier records
SELECT count(*)
FROM (
    SELECT count(condition_occurrence_id), condition_occurrence_id
    FROM measurement m
    INNER JOIN condition_occurrence co
    ON m.measurement_event_id = co.condition_occurrence_id
    AND measurement_concept_id =734306
    GROUP BY co.condition_occurrence_id
)
WHERE c > 1
```
> 3. the condition_occurrence record being modified is a cancer diagnosis as determined by condition_concept_id is descendant concept of 438112 neoplastic disease (should this be restricted to 443392 Malignant neoplastic disease) (Does class need to be 'ICDO Condition'? Of the source_concept_id or the condition_concept_id)

```
-- Number of records where modified condition_concept_id is either of class ICDO Condition or is a descendant concept of 438112 "neoplastic disease"
SELECT count(*)
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
```

> Final/ full logic for "correct" records

```
SELECT *
-- SELECT count(DISTINCT measurement_id)
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
```


## How many dates are valid
> Date should be after date of birth and before date of death, if exists

```
SELECT measurement_id
--SELECT count(measurement_id)
FROM (
    SELECT m.measurement_id
        , CASE WHEN p.birth_datetime > m.measurement_datetime THEN 1
                WHEN d.death_datetime < m.measurement_datetime THEN 1
                ELSE 0 END AS invalid_measurement_datetime
    FROM measurement m
    INNER JOIN person p
    ON m.person_id=p.person_id
    AND measurement_concept_id = 734306 
    LEFT JOIN death d
    ON m.person_id=d.person_id
)
WHERE invalid_measurement_datetime > 0
```


 Proportion of correct records (is this derived data point separate?)
 How many records are "incorrect"

## What are the data sources of Date of Initial Diagnosis records