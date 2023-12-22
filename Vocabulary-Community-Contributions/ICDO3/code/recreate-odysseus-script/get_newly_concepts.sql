DROP TABLE IF EXISTS icdoscript.QA_get_newly_concepts;
CREATE TABLE icdoscript.QA_get_newly_concepts (
	vocabulary_id VARCHAR(20),
	domain_id VARCHAR(20),
	cnt BIGINT
);

INSERT INTO icdoscript.QA_get_newly_concepts
SELECT new.vocabulary_id,
	new.domain_id,
	COUNT(*) AS cnt
FROM icdoscript.concept new
LEFT JOIN omopcdm_jan24.concept old ON old.concept_id = new.concept_id
WHERE old.concept_id IS NULL
	AND new.domain_id <> 'Metadata'
GROUP BY new.vocabulary_id,
	new.domain_id