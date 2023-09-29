/*
Newly added concepts and their standard concept status

Usage: select * from qa_tests.get_newly_concepts_standard_concept_status();
will show the difference between current schema and prodv5

or: select * from qa_tests.get_newly_concepts_standard_concept_status(pCompareWith=>'devv5');
will show the difference between current schema and devv5 (you can use any schema name)
*/

set search_path to dev;

CREATE OR REPLACE FUNCTION dev.get_newly_concepts_standard_concept_status (pCompareWith VARCHAR DEFAULT 'prod')
RETURNS TABLE
(
	vocabulary_id VARCHAR(20),
	new_standard_concept TEXT,
	cnt BIGINT
)
AS $BODY$
BEGIN
	RETURN QUERY
	EXECUTE FORMAT ($$
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
		FROM concept new
		LEFT JOIN %I.concept old ON old.concept_id = new.concept_id
		LEFT JOIN concept_relationship r ON r.concept_id_1 = new.concept_id
			AND relationship_id = 'Maps to'
			AND r.invalid_reason IS NULL
			AND r.concept_id_1 <> r.concept_id_2
		WHERE old.concept_id IS NULL
		GROUP BY new.vocabulary_id,
			new.standard_concept,
			r.relationship_id$$, LOWER(pCompareWith));
END;
$BODY$
LANGUAGE 'plpgsql' STABLE SECURITY INVOKER;

select * from dev.get_newly_concepts_standard_concept_status('prod')