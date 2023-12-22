CREATE OR REPLACE FUNCTION check_stage_tables ()
RETURNS TABLE (
	error_text TEXT,
	rows_count BIGINT
) AS
$BODY$
BEGIN
	RETURN QUERY
	SELECT reason, COUNT(*) FROM (
		--concept_relationship_stage
		SELECT
			CASE WHEN v1.vocabulary_id IS NOT NULL AND v2.vocabulary_id IS NOT NULL
					AND COALESCE (v1.latest_update, v2.latest_update) IS NULL THEN 'concept_relationship_stage contains a vocabulary, that is not affected by the SetLatestUpdate: '||crs.vocabulary_id_1
				WHEN crs.valid_start_date IS NULL THEN 'concept_relationship_stage.valid_start_date is null'
				WHEN crs.valid_end_date IS NULL THEN 'concept_relationship_stage.valid_end_date is null'
				WHEN ((crs.invalid_reason IS NULL AND crs.valid_end_date <> TO_DATE('20991231', 'yyyymmdd'))
					OR (crs.invalid_reason IS NOT NULL AND crs.valid_end_date = TO_DATE('20991231', 'yyyymmdd')))
					THEN 'wrong concept_relationship_stage.invalid_reason: '||COALESCE(crs.invalid_reason,'NULL')||' for '||TO_CHAR(crs.valid_end_date,'YYYYMMDD')
				WHEN crs.valid_end_date < crs.valid_start_date THEN 'concept_relationship_stage.valid_end_date < concept_relationship_stage.valid_start_date: '||TO_CHAR(crs.valid_end_date,'YYYYMMDD')||'+'||TO_CHAR(crs.valid_start_date,'YYYYMMDD')
				WHEN date_trunc('day', (crs.valid_start_date)) <> crs.valid_start_date THEN 'wrong format for concept_relationship_stage.valid_start_date (not truncated): '||TO_CHAR(crs.valid_start_date,'YYYYMMDD HH24:MI:SS')
				WHEN date_trunc('day', (crs.valid_end_date)) <> crs.valid_end_date THEN 'wrong format for concept_relationship_stage.valid_end_date (not truncated to YYYYMMDD): '||TO_CHAR(crs.valid_end_date,'YYYYMMDD HH24:MI:SS')
				WHEN COALESCE(crs.invalid_reason, 'D') <> 'D' THEN 'wrong value for concept_relationship_stage.invalid_reason: '||crs.invalid_reason
				WHEN crs.concept_code_1 = '' THEN 'concept_relationship_stage contains concept_code_1 which is empty ('''')'
				WHEN crs.concept_code_2 = '' THEN 'concept_relationship_stage contains concept_code_2 which is empty ('''')'
				WHEN c1.concept_code IS NULL AND cs1.concept_code IS NULL THEN 'concept_code_1+vocabulary_id_1 not found in the concept/concept_stage: '||crs.concept_code_1||'+'||crs.vocabulary_id_1
				WHEN c2.concept_code IS NULL AND cs2.concept_code IS NULL THEN 'concept_code_2+vocabulary_id_2 not found in the concept/concept_stage: '||crs.concept_code_2||'+'||crs.vocabulary_id_2
				WHEN v1.vocabulary_id IS NULL THEN 'vocabulary_id_1 not found in the vocabulary: '||CASE WHEN crs.vocabulary_id_1='' THEN '''''' ELSE crs.vocabulary_id_1 END
				WHEN v2.vocabulary_id IS NULL THEN 'vocabulary_id_2 not found in the vocabulary: '||CASE WHEN crs.vocabulary_id_2='' THEN '''''' ELSE crs.vocabulary_id_2 END
				WHEN rl.relationship_id IS NULL THEN 'relationship_id not found in the relationship: '||CASE WHEN crs.relationship_id='' THEN '''''' ELSE crs.relationship_id END
				WHEN crs.valid_start_date > CURRENT_DATE AND crs.valid_start_date<>v1.latest_update THEN 'concept_relationship_stage.valid_start_date is greater than the current date: '||TO_CHAR(crs.valid_start_date,'YYYYMMDD')
				WHEN crs.valid_start_date < TO_DATE ('19000101', 'yyyymmdd') THEN 'concept_relationship_stage.valid_start_date is before 1900: '||TO_CHAR(crs.valid_start_date,'YYYYMMDD')
				ELSE NULL
			END AS reason
			FROM icdoscript.concept_relationship_stage crs
				LEFT JOIN omopcdm_jan24.concept c1 ON c1.concept_code = crs.concept_code_1 AND c1.vocabulary_id = crs.vocabulary_id_1
				LEFT JOIN icdoscript.concept_stage cs1 ON cs1.concept_code = crs.concept_code_1 AND cs1.vocabulary_id = crs.vocabulary_id_1
				LEFT JOIN omopcdm_jan24.concept c2 ON c2.concept_code = crs.concept_code_2 AND c2.vocabulary_id = crs.vocabulary_id_2
				LEFT JOIN icdoscript.concept_stage cs2 ON cs2.concept_code = crs.concept_code_2 AND cs2.vocabulary_id = crs.vocabulary_id_2
				LEFT JOIN omopcdm_jan24.vocabulary v1 ON v1.vocabulary_id = crs.vocabulary_id_1
				LEFT JOIN omopcdm_jan24.vocabulary v2 ON v2.vocabulary_id = crs.vocabulary_id_2
				LEFT JOIN omopcdm_jan24.relationship rl ON rl.relationship_id = crs.relationship_id
		UNION ALL
		SELECT
			'duplicates in concept_relationship_stage were found: '||crs.concept_code_1||'+'||crs.concept_code_2||'+'||crs.vocabulary_id_1||'+'||crs.vocabulary_id_2||'+'||crs.relationship_id AS reason
			FROM icdoscript.concept_relationship_stage crs
			GROUP BY crs.concept_code_1, crs.concept_code_2, crs.vocabulary_id_1, crs.vocabulary_id_2, crs.relationship_id HAVING COUNT (*) > 1
		UNION ALL
		--concept_stage
		SELECT
			CASE WHEN v.vocabulary_id IS NOT NULL AND v.latest_update IS NULL THEN 'concept_stage contains a vocabulary, that is not affected by the SetLatestUpdate: '||cs.vocabulary_id
				WHEN v.vocabulary_id IS NULL THEN 'concept_stage.vocabulary_id not found in the vocabulary: '||CASE WHEN cs.vocabulary_id='' THEN '''''' ELSE cs.vocabulary_id END
				WHEN cs.valid_end_date < cs.valid_start_date THEN
					--it's absolutely ok if valid_end_date < valid_start_date when valid_start_date = latest_update, because generic_update keeps the old date. check it
					CASE WHEN cs.valid_start_date<>v.latest_update THEN
						'concept_stage.valid_end_date < concept_stage.valid_start_date: '||TO_CHAR(cs.valid_end_date,'YYYYMMDD')||'+'||TO_CHAR(cs.valid_start_date,'YYYYMMDD')
					ELSE
						--but even if valid_start_date = latest_update we should check what if valid_start_date in the 'concept' bigger than valid_end_date in the 'concept_stage'?
						CASE WHEN cs.valid_end_date<c.valid_start_date THEN
							'concept_stage.valid_end_date < concept.valid_start_date: '||TO_CHAR(cs.valid_end_date,'YYYYMMDD')||'+'||TO_CHAR(c.valid_start_date,'YYYYMMDD')
						END
					END
				WHEN COALESCE(cs.invalid_reason, 'D') NOT IN ('D','U') THEN 'wrong value for concept_stage.invalid_reason: '||CASE WHEN cs.invalid_reason='' THEN '''''' ELSE cs.invalid_reason END
				WHEN date_trunc('day', (cs.valid_start_date)) <> cs.valid_start_date THEN 'wrong format for concept_stage.valid_start_date (not truncated): '||TO_CHAR(cs.valid_start_date,'YYYYMMDD HH24:MI:SS')
				WHEN date_trunc('day', (cs.valid_end_date)) <> cs.valid_end_date THEN 'wrong format for concept_stage.valid_end_date (not truncated to YYYYMMDD): '||TO_CHAR(cs.valid_end_date,'YYYYMMDD HH24:MI:SS')
				--WHEN (((cs.invalid_reason IS NULL AND cs.valid_end_date <> TO_DATE('20991231', 'yyyymmdd')) AND cs.vocabulary_id NOT IN (SELECT TRIM(v) FROM UNNEST(STRING_TO_ARRAY((SELECT var_value FROM devv5.config$ WHERE var_name='special_vocabularies'),',')) v))
				WHEN ((cs.invalid_reason IS NULL AND cs.valid_end_date <> TO_DATE('20991231', 'yyyymmdd')) 
					OR (cs.invalid_reason IS NOT NULL AND cs.valid_end_date = TO_DATE('20991231', 'yyyymmdd'))) THEN 'wrong concept_stage.invalid_reason: '||COALESCE(cs.invalid_reason,'NULL')||' for '||TO_CHAR(cs.valid_end_date,'YYYYMMDD')
				WHEN d.domain_id IS NULL AND cs.domain_id IS NOT NULL THEN 'domain_id not found in the domain: '||CASE WHEN cs.domain_id='' THEN '''''' ELSE cs.domain_id END
				WHEN cc.concept_class_id IS NULL AND cs.concept_class_id IS NOT NULL THEN 'concept_class_id not found in the concept_class: '||CASE WHEN cs.concept_class_id='' THEN '''''' ELSE cs.concept_class_id END
				WHEN COALESCE(cs.standard_concept, 'S') NOT IN ('C','S') THEN 'wrong value for standard_concept: '||CASE WHEN cs.standard_concept='' THEN '''''' ELSE cs.standard_concept END
				WHEN cs.valid_start_date IS NULL THEN 'concept_stage.valid_start_date is null'
				WHEN cs.valid_end_date IS NULL THEN 'concept_stage.valid_end_date is null'
				WHEN cs.valid_start_date < TO_DATE ('19000101', 'yyyymmdd') THEN 'concept_stage.valid_start_date is before 1900: '||TO_CHAR(cs.valid_start_date,'YYYYMMDD')
				WHEN COALESCE(cs.concept_name, '') = '' THEN 'empty concept_stage.concept_name ('''')'
				WHEN cs.concept_code = '' THEN 'empty concept_stage.concept_code ('''')'
				WHEN cs.concept_name<>TRIM(cs.concept_name) THEN 'concept_stage.concept_name not trimmed for concept_code: '||cs.concept_code
				WHEN cs.concept_code<>TRIM(cs.concept_code) THEN 'concept_stage.concept_code not trimmed for concept_name: '||cs.concept_name
				ELSE NULL
			END AS reason
		FROM icdoscript.concept_stage cs
			LEFT JOIN omopcdm_jan24.vocabulary v ON v.vocabulary_id = cs.vocabulary_id
			LEFT JOIN omopcdm_jan24.domain d ON d.domain_id = cs.domain_id
			LEFT JOIN omopcdm_jan24.concept_class cc ON cc.concept_class_id = cs.concept_class_id
			LEFT JOIN omopcdm_jan24.concept c ON c.concept_code = cs.concept_code AND c.vocabulary_id=cs.vocabulary_id
		UNION ALL
		--concept_synonym_stage
		SELECT
			CASE WHEN v.vocabulary_id IS NOT NULL AND v.latest_update IS NULL THEN 'concept_synonym_stage contains a vocabulary, that is not affected by the SetLatestUpdate: '||css.synonym_vocabulary_id
				WHEN v.vocabulary_id IS NULL THEN 'concept_synonym_stage.synonym_vocabulary_id not found in the vocabulary: '||CASE WHEN css.synonym_vocabulary_id='' THEN '''''' ELSE css.synonym_vocabulary_id END
				WHEN css.synonym_name = '' THEN 'empty synonym_name ('''')'
				WHEN css.synonym_concept_code = '' THEN 'empty synonym_concept_code ('''')'
				WHEN c.concept_code IS NULL AND cs.concept_code IS NULL THEN 'synonym_concept_code+synonym_vocabulary_id not found in the concept/concept_stage: '||css.synonym_concept_code||'+'||css.synonym_vocabulary_id
				WHEN css.synonym_name<>TRIM(css.synonym_name) THEN 'synonym_name not trimmed for concept_code: '||css.synonym_concept_code
				WHEN css.synonym_concept_code<>TRIM(css.synonym_concept_code) THEN 'synonym_concept_code not trimmed for synonym_name: '||css.synonym_name
				WHEN c_lng.concept_id IS NULL THEN 'language_concept_id not found in the concept: '||css.language_concept_id
				ELSE NULL
			END AS reason
		FROM icdoscript.concept_synonym_stage css
			LEFT JOIN omopcdm_jan24.vocabulary v ON v.vocabulary_id = css.synonym_vocabulary_id
			LEFT JOIN omopcdm_jan24.concept c ON c.concept_code = css.synonym_concept_code AND c.vocabulary_id = css.synonym_vocabulary_id
			LEFT JOIN icdoscript.concept_stage cs ON cs.concept_code = css.synonym_concept_code AND cs.vocabulary_id = css.synonym_vocabulary_id
			LEFT JOIN omopcdm_jan24.concept c_lng ON c_lng.concept_id = css.language_concept_id
		UNION ALL
		SELECT
			'duplicates in concept_stage were found: '||cs.concept_code||'+'||cs.vocabulary_id AS reason
			FROM icdoscript.concept_stage cs
			GROUP BY cs.concept_code, cs.vocabulary_id HAVING COUNT (*) > 1
		UNION ALL
		--pack_content_stage
		SELECT
			'duplicates in pack_content_stage were found: '||pcs.pack_concept_code||'+'||pcs.pack_vocabulary_id||pcs.drug_concept_code||'+'||pcs.drug_vocabulary_id||'+'||pcs.amount AS reason
			FROM icdoscript.pack_content_stage pcs
			GROUP BY pcs.pack_concept_code, pcs.pack_vocabulary_id, pcs.drug_concept_code, pcs.drug_vocabulary_id, pcs.amount HAVING COUNT (*) > 1
		UNION ALL
		--drug_strength_stage
		SELECT
			'duplicates in drug_strength_stage were found: '||dcs.drug_concept_code||'+'||dcs.vocabulary_id_1||
				dcs.ingredient_concept_code||'+'||dcs.vocabulary_id_2||'+'||TO_CHAR(dcs.amount_value, 'FM9999999999999999999990.999999999999999999999') AS reason
			FROM icdoscript.drug_strength_stage dcs
			GROUP BY dcs.drug_concept_code, dcs.vocabulary_id_1, dcs.ingredient_concept_code, dcs.vocabulary_id_2, dcs.amount_value HAVING COUNT (*) > 1
	) AS s0
	WHERE reason IS NOT NULL
	GROUP BY reason;
END;
$BODY$ LANGUAGE 'plpgsql' SECURITY INVOKER;

DROP TABLE IF EXISTS icdoscript.QA_check_stage_tables;
CREATE TABLE icdoscript.QA_check_stage_tables (
	error_text TEXT,
	rows_count BIGINT
);

INSERT INTO icdoscript.QA_check_stage_tables
SELECT * 
FROM check_stage_tables();
