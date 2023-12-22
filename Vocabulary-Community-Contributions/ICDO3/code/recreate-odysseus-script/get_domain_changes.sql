DROP TABLE IF EXISTS icdoscript.QA_get_domain_changes;
CREATE TABLE icdoscript.QA_get_domain_changes (
	vocabulary_id VARCHAR(20),
	old_domain_id VARCHAR(20),
	new_domain_id VARCHAR(20),
	cnt BIGINT
);

INSERT INTO icdoscript.QA_get_domain_changes
SELECT new.vocabulary_id,
	old.domain_id AS old_domain_id,
	new.domain_id AS new_domain_id,
	COUNT(*) AS cnt
FROM icdoscript.concept new
JOIN omopcdm_jan24.concept old ON old.concept_id = new.concept_id
	AND new.domain_id <> old.domain_id
GROUP BY new.vocabulary_id,
	old.domain_id,
	new.domain_id