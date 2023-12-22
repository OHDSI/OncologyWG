DROP TABLE IF EXISTS icdoscript.QA_get_new_vocabulary_dependencies;
CREATE TABLE icdoscript.QA_get_new_vocabulary_dependencies (
	vocabulary_id_1 VARCHAR(20),
	vocabulary_id_2 VARCHAR(20),
	cnt BIGINT
);

INSERT INTO icdoscript.QA_get_new_vocabulary_dependencies
SELECT c1.vocabulary_id,
	c2.vocabulary_id,
	COUNT(*) AS cnt
FROM icdoscript.concept_relationship cr
JOIN icdoscript.concept c1 ON c1.concept_id = cr.concept_id_1
JOIN icdoscript.concept c2 ON c2.concept_id = cr.concept_id_2
WHERE cr.relationship_id = 'Maps to'
	AND cr.invalid_reason IS NULL
	AND c1.vocabulary_id <> c2.vocabulary_id
	AND NOT EXISTS (
		SELECT 1
		FROM omopcdm_jan24.concept_relationship r_int
		JOIN omopcdm_jan24.concept c1_int ON c1_int.concept_id = r_int.concept_id_1
		JOIN omopcdm_jan24.concept c2_int ON c2_int.concept_id = r_int.concept_id_2
		WHERE r_int.relationship_id = 'Maps to'
			AND r_int.invalid_reason IS NULL
			AND c1_int.vocabulary_id = c1.vocabulary_id
			AND c2_int.vocabulary_id = c2.vocabulary_id
		)
GROUP BY c1.vocabulary_id,
	c2.vocabulary_id