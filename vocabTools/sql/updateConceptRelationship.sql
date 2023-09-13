DELETE FROM dev.concept_relationship
WHERE EXISTS (
    SELECT 1
    FROM dev.temp_concept_relationship_data AS temp
    WHERE
        dev.concept_relationship.concept_id_1 = temp.concept_id_1
        AND dev.concept_relationship.concept_id_2 = temp.concept_id_2
        AND dev.concept_relationship.relationship_id = temp.relationship_id
        AND temp.invalid_reason = 'D'
);

INSERT INTO dev.concept_relationship SELECT * FROM dev.temp_concept_relationship_data;