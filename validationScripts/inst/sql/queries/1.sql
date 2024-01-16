-- 1  Person_ids of persons with cancer diagnosis

SELECT DISTINCT co.person_id
FROM @cdmDatabaseSchema.condition_occurrence co
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