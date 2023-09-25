-- QA tests for Onc Voc
set search_path to dev;
-- 0 helper func

create or REPLACE FUNCTION dev.numeric_to_text (
  v numeric
)
RETURNS TEXT AS
$BODY$
  SELECT TRIM(TRAILING '.' FROM TO_CHAR(v, 'FM9999999999999999999990.999999999999999999999'));
$BODY$
LANGUAGE 'sql' IMMUTABLE STRICT PARALLEL SAFE;

-- 1 get_summary - compares concept, concept_relationship and concept_ances

CREATE OR REPLACE FUNCTION dev.get_summary (
	table_name TEXT,
	pCompareWith VARCHAR DEFAULT 'prod',
	pConsiderStandardField BOOLEAN DEFAULT TRUE,
	pConsiderInvalidField BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
	vocabulary_id_1 concept.vocabulary_id%TYPE,
	vocabulary_id_2 concept.vocabulary_id%TYPE,
	standard_concept concept.standard_concept%TYPE,
	concept_class_id concept.concept_class_id%TYPE,
	relationship_id concept_relationship.relationship_id%TYPE,
	invalid_reason concept.invalid_reason%TYPE,
	concept_delta INT8,
	concept_delta_percentage TEXT
) AS
$BODY$
/*
The function returns a summary (delta) for basic tables in the current schema: concept, concept_relationship and concept_ancestor
For the concept table, the number of concepts in the context of standard_concept (can be disabled, default enabled), concept_class_id and invalid_reason (can be disabled, default enabled) is taken and compared with the table from the target schema (default - prodv5)
For the concept_relationship table, the number of concepts in the context of vocabulary_id_1, vocabulary_id_2, relationship_id and invalid_reason is taken and compared with the table from the target schema
For the concept_ancestor table, the number of concepts in the context of vocabulary_id (ancestor_concept_id) is taken and compared with the table from the target schema
The last field shows the percentage change in the context (if the target schema does not contain rows in this context, then the last column will be null)

Examples:
select * from qa_tests.get_summary ('concept','devv5');
select * from qa_tests.get_summary (table_name=>'concept',pCompareWith=>'devv5');
select * from qa_tests.get_summary (table_name=>'concept',pCompareWith=>'devv5',pConsiderStandardField=>FALSE,pConsiderInvalidField=>FALSE);
select * from qa_tests.get_summary (table_name=>'concept_relationship',pCompareWith=>'devv5');
select * from qa_tests.get_summary (table_name=>'concept_ancestor',pCompareWith=>'devv5');
*/
DECLARE
	pGeneratedStmt_c TEXT;
	pGeneratedStmt_cr TEXT;
	pGeneratedStmt_ca TEXT;
	iTableName TEXT:=LOWER(table_name);
BEGIN
	pCompareWith:=LOWER(pCompareWith);
	IF iTableName NOT IN ('concept', 'concept_relationship', 'concept_ancestor') THEN
		RAISE EXCEPTION 'Wrong table name';
	END IF;

	--delta for concept
	pGeneratedStmt_c:=FORMAT($$
		SELECT COALESCE(s0.vocabulary_id, s1.vocabulary_id) AS vocabulary_id_1,
			NULL::VARCHAR AS vocabulary_id_2,
			COALESCE(NULLIF(s0.standard_concept, 'X'), NULLIF(s1.standard_concept, 'X'))::VARCHAR AS standard_concept,
			COALESCE(s0.concept_class_id, s1.concept_class_id) AS concept_class_id,
			NULL::VARCHAR AS relationship_id,
			COALESCE(NULLIF(s0.invalid_reason, 'X'), NULLIF(s1.invalid_reason, 'X'))::VARCHAR AS invalid_reason,
			COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) AS cnt_delta,
			/*CASE WHEN COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) > 0 THEN
				'+'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%'
			ELSE
				'-'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s1.cnt, 0) - COALESCE(s0.cnt, 0))::NUMERIC/COALESCE(s0.cnt, 1),3))||'%%'
			END AS concept_delta_percentage*/
			--dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%' AS concept_delta_percentage
			dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - s1.cnt)::NUMERIC/s1.cnt,3))||'%%' AS concept_delta_percentage
		FROM (
			SELECT vocabulary_id,
				CASE WHEN %2$L THEN
					COALESCE(standard_concept, 'X')
				ELSE
					'-'
				END AS standard_concept,
				concept_class_id,
				CASE WHEN %3$L THEN
					COALESCE(invalid_reason, 'X')
				ELSE
					'-'
				END AS invalid_reason,
				COUNT(*) AS cnt
			FROM concept
			GROUP BY 1,
				2,
				3,
				4
			) s0
		FULL OUTER JOIN (
			SELECT vocabulary_id,
				CASE WHEN %2$L THEN
					COALESCE(standard_concept, 'X')
				ELSE
					'-'
				END AS standard_concept,
				concept_class_id,
				CASE WHEN %3$L THEN
					COALESCE(invalid_reason, 'X')
				ELSE
					'-'
				END AS invalid_reason,
				COUNT(*) AS cnt
			FROM %1$I.concept
			GROUP BY 1,
				2,
				3,
				4
			) s1 USING (
				vocabulary_id,
				standard_concept,
				concept_class_id,
				invalid_reason
				)
		WHERE COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) <> 0$$,
		pCompareWith,
		pConsiderStandardField,
		pConsiderInvalidField
	);

	--delta for concept_relationship
	pGeneratedStmt_cr:=FORMAT($$
		SELECT COALESCE(s0.vocabulary_id_1, s1.vocabulary_id_1) AS vocabulary_id_1,
			COALESCE(s0.vocabulary_id_2, s1.vocabulary_id_2) AS vocabulary_id_2,
			NULL::VARCHAR AS standard_concept,
			NULL::VARCHAR AS concept_class_id,
			COALESCE(s0.relationship_id, s1.relationship_id) AS relationship_id,
			COALESCE(NULLIF(s0.invalid_reason, 'X'), NULLIF(s1.invalid_reason, 'X'))::VARCHAR AS invalid_reason,
			COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) AS cnt_delta,
			/*CASE WHEN COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) > 0 THEN
				'+'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%'
			ELSE
				'-'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s1.cnt, 0) - COALESCE(s0.cnt, 0))::NUMERIC/COALESCE(s0.cnt, 1),3))||'%%'
			END AS concept_delta_percentage*/
			--dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%' AS concept_delta_percentage
			dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - s1.cnt)::NUMERIC/s1.cnt,3))||'%%' AS concept_delta_percentage
		FROM (
			SELECT c1.vocabulary_id AS vocabulary_id_1,
				c2.vocabulary_id AS vocabulary_id_2,
				cr.relationship_id,
				COALESCE(cr.invalid_reason, 'X') AS invalid_reason,
				COUNT(*) AS cnt
			FROM concept_relationship cr
			JOIN concept c1 ON c1.concept_id = cr.concept_id_1
			JOIN concept c2 ON c2.concept_id = cr.concept_id_2
			GROUP BY 1,
				2,
				3,
				4
			) s0
		FULL OUTER JOIN (
			SELECT c1.vocabulary_id AS vocabulary_id_1,
				c2.vocabulary_id AS vocabulary_id_2,
				cr.relationship_id,
				COALESCE(cr.invalid_reason, 'X') AS invalid_reason,
				COUNT(*) AS cnt
			FROM %1$I.concept_relationship cr
			JOIN %1$I.concept c1 ON c1.concept_id = cr.concept_id_1
			JOIN %1$I.concept c2 ON c2.concept_id = cr.concept_id_2
			GROUP BY 1,
				2,
				3,
				4
			) s1 USING (
				vocabulary_id_1,
				vocabulary_id_2,
				relationship_id,
				invalid_reason
				)
		WHERE COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) <> 0$$,
		pCompareWith
	);

	--delta for concept_ancestor
	pGeneratedStmt_ca:=FORMAT($$
		SELECT COALESCE(s0.vocabulary_id, s1.vocabulary_id) AS vocabulary_id_1,
			NULL::VARCHAR AS vocabulary_id_2,
			NULL::VARCHAR AS standard_concept,
			NULL::VARCHAR AS concept_class_id,
			NULL::VARCHAR AS relationship_id,
			NULL::VARCHAR AS invalid_reason,
			COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) AS cnt_delta,
			/*CASE WHEN COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) > 0 THEN
				'+'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%'
			ELSE
				'-'||dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s1.cnt, 0) - COALESCE(s0.cnt, 0))::NUMERIC/COALESCE(s0.cnt, 1),3))||'%%'
			END AS concept_delta_percentage*/
			--dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0))::NUMERIC/COALESCE(s1.cnt, 1),3))||'%%' AS concept_delta_percentage
			dev.NUMERIC_TO_TEXT(ROUND(100*(COALESCE(s0.cnt, 0) - s1.cnt)::NUMERIC/s1.cnt,3))||'%%' AS concept_delta_percentage
		FROM (
			SELECT c.vocabulary_id,
				COUNT(*) AS cnt
			FROM concept_ancestor ca
			JOIN concept c ON c.concept_id = ca.ancestor_concept_id
			GROUP BY 1
			) s0
		FULL OUTER JOIN (
			SELECT c.vocabulary_id,
				COUNT(*) AS cnt
			FROM %1$I.concept_ancestor ca
			JOIN %1$I.concept c ON c.concept_id = ca.ancestor_concept_id
			GROUP BY 1
			) s1 USING (
				vocabulary_id
				)
		WHERE COALESCE(s0.cnt, 0) - COALESCE(s1.cnt, 0) <> 0$$,
		pCompareWith
	);

	IF iTableName = 'concept' THEN
		RETURN QUERY EXECUTE pGeneratedStmt_c;
	ELSIF iTableName = 'concept_relationship' THEN
		SET LOCAL parallel_tuple_cost=0; --force parallel execution
		RETURN QUERY EXECUTE pGeneratedStmt_cr;
	ELSE
		RETURN QUERY EXECUTE pGeneratedStmt_ca;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

select 'concept' as table_name, * from dev.get_summary ('concept','prod')
union ALL
select 'concept_relationship' as table_name, * from dev.get_summary ('concept_relationship','prod')
union ALL
select 'concept_ancestor' as table_name, * from dev.get_summary ('concept_ancestor','prod');

