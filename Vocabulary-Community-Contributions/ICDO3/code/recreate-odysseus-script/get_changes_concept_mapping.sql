DROP TABLE IF EXISTS icdoscript.QA_get_changes_concept_mapping;
CREATE TABLE icdoscript.QA_get_changes_concept_mapping (
	vocabulary_id VARCHAR(20),
	old_mapped_domains TEXT,
	new_mapped_domains TEXT,
	cnt BIGINT
);

INSERT INTO icdoscript.QA_get_changes_concept_mapping
SELECT s_all.vocabulary_id,
	s_all.old_mapped_domains,
	s_all.new_mapped_domains,
	COUNT(*) AS cnt
FROM (
	SELECT new.vocabulary_id,
		CASE 
			WHEN old.concept_id IS NULL
				THEN 'New concept'
			ELSE COALESCE(old.domains, 'No mapping')
			END AS old_mapped_domains,
		COALESCE(new.domains, 'No mapping') AS new_mapped_domains
	FROM (
		SELECT c1.vocabulary_id,
			c1.concept_id,
			STRING_AGG(DISTINCT c2.domain_id, '/' ORDER BY c2.domain_id) AS domains
		FROM icdoscript.concept c1
		LEFT JOIN icdoscript.concept_relationship r ON r.concept_id_1 = c1.concept_id
			AND r.invalid_reason IS NULL
			AND r.relationship_id = 'Maps to'
		LEFT JOIN icdoscript.concept c2 ON c2.concept_id = r.concept_id_2
		GROUP BY c1.vocabulary_id,
			c1.concept_id
		) AS new
	LEFT JOIN (
		SELECT c1.concept_id,
			STRING_AGG(DISTINCT c2.domain_id, '/' ORDER BY c2.domain_id) AS domains
		FROM omopcdm_jan24.concept c1
		LEFT JOIN omopcdm_jan24.concept_relationship r ON r.concept_id_1 = c1.concept_id
			AND r.invalid_reason IS NULL
			AND r.relationship_id = 'Maps to'
		LEFT JOIN omopcdm_jan24.concept c2 ON c2.concept_id = r.concept_id_2
		GROUP BY c1.concept_id
		) AS old ON old.concept_id = new.concept_id
	WHERE new.domains IS DISTINCT FROM old.domains
	) AS s_all
GROUP BY s_all.vocabulary_id,
	s_all.old_mapped_domains,
	s_all.new_mapped_domains