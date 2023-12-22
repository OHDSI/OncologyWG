DROP TABLE IF EXISTS icdoscript.QA_get_newly_concepts_standard_concept_status;
CREATE TABLE icdoscript.QA_get_newly_concepts_standard_concept_status (
	vocabulary_id VARCHAR(20),
	new_standard_concept TEXT,
	cnt BIGINT
);

INSERT INTO icdoscript.QA_get_newly_concepts_standard_concept_status
SELECT new.vocabulary_id,
	CASE 
		WHEN new.standard_concept = 'S'
			THEN 'Standard'
		WHEN new.standard_concept = 'C'
			AND r.relationship_id = 'Maps to'
			THEN 'Classification with mapping'
		WHEN new.standard_concept = 'C'
			AND r.relationship_id IS NULL
			THEN 'Classification without mapping'
		WHEN new.standard_concept IS NULL
			AND r.relationship_id = 'Maps to'
			THEN 'Non-standard with mapping'
		ELSE 'Non-standard without mapping'
		END AS new_standard_concept,
	COUNT(DISTINCT new.concept_id) AS cnt --there can be more than one Maps to, so DISTINCT
FROM icdoscript.concept new
LEFT JOIN omopcdm_jan24.concept old ON old.concept_id = new.concept_id
LEFT JOIN icdoscript.concept_relationship r ON r.concept_id_1 = new.concept_id
	AND relationship_id = 'Maps to'
	AND r.invalid_reason IS NULL
	AND r.concept_id_1 <> r.concept_id_2
WHERE old.concept_id IS NULL
GROUP BY new.vocabulary_id,
	new.standard_concept,
	r.relationship_id