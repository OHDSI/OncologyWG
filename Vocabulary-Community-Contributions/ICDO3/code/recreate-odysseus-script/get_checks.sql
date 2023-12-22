DROP TABLE IF EXISTS icdoscript.QA_get_checks;
CREATE TABLE icdoscript.QA_get_checks (
	check_id int4,
	check_name VARCHAR(1000),
	concept_id_1 int4,
	concept_id_2 int4,
	relationship_id VARCHAR(20),
	valid_start_date DATE,
	valid_end_date DATE,
	invalid_reason VARCHAR(1)
);

INSERT INTO icdoscript.QA_get_checks
SELECT 1 check_id,
	'relationships cycle' AS check_name,
	r.*
FROM icdoscript.concept_relationship r,
	icdoscript.concept_relationship r_int
WHERE r.invalid_reason IS NULL
	AND r_int.concept_id_1 = r.concept_id_2
	AND r_int.concept_id_2 = r.concept_id_1
	AND r.concept_id_1 <> r.concept_id_2
	AND r_int.relationship_id = r.relationship_id
	AND r_int.invalid_reason IS NULL

INSERT INTO icdoscript.QA_get_checks
SELECT 2 check_id,
	'opposing relationships between same pair of concepts' AS check_name,
	r.*
FROM icdoscript.concept_relationship r,
	icdoscript.concept_relationship r_int,
	omopcdm_jan24.relationship rel
WHERE r.invalid_reason IS NULL
	AND r.relationship_id = rel.relationship_id
	AND r_int.concept_id_1 = r.concept_id_1
	AND r_int.concept_id_2 = r.concept_id_2
	AND r.concept_id_1 <> r.concept_id_2
	AND r_int.relationship_id = rel.reverse_relationship_id
	AND r_int.invalid_reason IS NULL

--relationships without reverse
INSERT INTO icdoscript.QA_get_checks
SELECT 3 check_id,
	'relationships without reverse' AS check_name,
	r.*
FROM icdoscript.concept_relationship r,
	omopcdm_jan24.relationship rel
WHERE r.relationship_id = rel.relationship_id
	AND NOT EXISTS (
		SELECT 1
		FROM icdoscript.concept_relationship r_int
		WHERE r_int.relationship_id = rel.reverse_relationship_id
			AND r_int.concept_id_1 = r.concept_id_2
			AND r_int.concept_id_2 = r.concept_id_1
		)

	/*--replacement relationships between different vocabularies (exclude RxNorm to RxNorm Ext OR RxNorm Ext to RxNorm OR SNOMED<->SNOMED Veterinary replacement relationships)
		--deprecated 20190227
		SELECT 4 check_id,
			r.*
		FROM concept_relationship r,
			concept c1,
			concept c2
		WHERE r.invalid_reason IS NULL
			AND r.concept_id_1 <> r.concept_id_2
			AND c1.concept_id = r.concept_id_1
			AND c2.concept_id = r.concept_id_2
			AND c1.vocabulary_id <> c2.vocabulary_id
			AND NOT (
				c1.vocabulary_id IN (
					'RxNorm',
					'RxNorm Extension'
					)
				AND c2.vocabulary_id IN (
					'RxNorm',
					'RxNorm Extension'
					)
				)
			AND NOT (
				c1.vocabulary_id IN (
					'SNOMED',
					'SNOMED Veterinary'
					)
				AND c2.vocabulary_id IN (
					'SNOMED',
					'SNOMED Veterinary'
					)
				)			
			AND r.relationship_id IN (
				'Concept replaced by',
				'Concept same_as to',
				'Concept alt_to to',
				'Concept poss_eq to',
				'Concept was_a to'
				)
			AND COALESCE(checkid, 4) = 4

		UNION ALL*/
--wrong relationships: 'Maps to' to 'D' or 'U'; replacement relationships to 'D'
INSERT INTO icdoscript.QA_get_checks
SELECT 5 check_id, $$wrong relationships: 'Maps to' TO 'D' OR 'U'; replacement relationships TO 'D'$$ AS check_name,
	r.*
FROM icdoscript.concept c2,
	icdoscript.concept_relationship r
WHERE c2.concept_id = r.concept_id_2
	AND (
		(
			c2.invalid_reason IN (
				'D',
				'U'
				)
			AND r.relationship_id = 'Maps to'
			)
		OR (
			c2.invalid_reason = 'D'
			AND r.relationship_id IN (
				'Concept replaced by',
				'Concept same_as to',
				'Concept alt_to to',
				'Concept was_a to'
				)
			)
		)
	AND r.invalid_reason IS NULL

--direct and reverse mappings are not same
INSERT INTO icdoscript.QA_get_checks
SELECT 6 check_id,
	'direct and reverse mappings are not same' AS check_name,
	r.*
FROM icdoscript.concept_relationship r,
	omopcdm_jan24.relationship rel,
	icdoscript.concept_relationship r_int
WHERE r.relationship_id = rel.relationship_id
	AND r_int.relationship_id = rel.reverse_relationship_id
	AND r_int.concept_id_1 = r.concept_id_2
	AND r_int.concept_id_2 = r.concept_id_1
	AND (
		r.valid_end_date <> r_int.valid_end_date
		OR COALESCE(r.invalid_reason, 'X') <> COALESCE(r_int.invalid_reason, 'X')
		)

--	--wrong valid_start_date, valid_end_date or invalid_reason for the concept
--	SELECT 7 check_id,
--		'wrong valid_start_date, valid_end_date or invalid_reason for the concept' AS check_name,
--		c.concept_id,
--		NULL,
--		c.vocabulary_id,
--		c.valid_start_date,
--		c.valid_end_date,
--		c.invalid_reason
--	FROM icdoscript.concept c
--	JOIN icdoscript.vocabulary_conversion vc ON vc.vocabulary_id_v5 = c.vocabulary_id
--	WHERE (
--			c.valid_end_date < c.valid_start_date
--			OR (
--				c.valid_end_date = TO_DATE('20991231', 'YYYYMMDD')
--				AND c.invalid_reason IS NOT NULL
--				)
--			OR (
--				c.valid_end_date <> TO_DATE('20991231', 'YYYYMMDD')
--				AND c.invalid_reason IS NULL
--				--AND c.vocabulary_id NOT IN (SELECT TRIM(v) FROM UNNEST(STRING_TO_ARRAY((SELECT var_value FROM devv5.config$ WHERE var_name='special_vocabularies'),',')) v)
--				)
--			OR c.valid_start_date > COALESCE(vc.latest_update, CURRENT_DATE) + INTERVAL '15 year' --some concepts might be from near future (e.g. GGR, HCPCS) [AVOF-1015]/increased 20180928 for some NDC concepts
--			OR c.valid_start_date < TO_DATE('19000101', 'yyyymmdd') -- some concepts have a real date < 1970
--			)
--		AND COALESCE(checkid, 7) = 7
--
--	UNION ALL
--
--	--wrong valid_start_date, valid_end_date or invalid_reason for the concept_relationship
--	SELECT 8 check_id,
--		'wrong valid_start_date, valid_end_date or invalid_reason for the concept_relationship' AS check_name,
--		s0.concept_id_1,
--		s0.concept_id_2,
--		s0.relationship_id,
--		s0.valid_start_date,
--		s0.valid_end_date,
--		s0.invalid_reason
--	FROM (
--		SELECT r.*,
--			CASE 
--				WHEN (
--						r.valid_end_date = TO_DATE('20991231', 'YYYYMMDD')
--						AND r.invalid_reason IS NOT NULL
--						)
--					OR (
--						r.valid_end_date <> TO_DATE('20991231', 'YYYYMMDD')
--						AND r.invalid_reason IS NULL
--						)
--					OR (
--						r.valid_start_date > CURRENT_DATE
--						AND r.valid_start_date IS DISTINCT FROM GREATEST(vc1.latest_update, vc2.latest_update)
--						)
--					OR r.valid_start_date < TO_DATE('19700101', 'yyyymmdd')
--					THEN 1
--				ELSE 0
--				END check_flag
--		FROM icdoscript.concept_relationship r
--		JOIN icdoscript.concept c1 ON c1.concept_id = r.concept_id_1
--		JOIN icdoscript.concept c2 ON c2.concept_id = r.concept_id_2
--		LEFT JOIN icdoscript.vocabulary_conversion vc1 ON vc1.vocabulary_id_v5 = c1.vocabulary_id
--		LEFT JOIN icdoscript.vocabulary_conversion vc2 ON vc2.vocabulary_id_v5 = c2.vocabulary_id
--		) AS s0
--	WHERE check_flag = 1
--		AND COALESCE(checkid, 8) = 8
--
--	UNION ALL

	--RxE to Rx name duplications
	--tempopary disabled
	/*
	SELECT 9 check_id,
		'RxE to Rx name duplications' AS check_name,
		c2.concept_id,
		c1.concept_id,
		'Concept replaced by' AS relationship_id,
		NULL AS valid_start_date,
		NULL AS valid_end_date,
		NULL AS invalid_reason
	FROM concept c1
	JOIN concept c2 ON upper(c2.concept_name) = upper(c1.concept_name)
		AND c2.concept_class_id = c1.concept_class_id
		AND c2.vocabulary_id = 'RxNorm Extension'
		AND c2.invalid_reason IS NULL
	WHERE c1.vocabulary_id = 'RxNorm'
		AND c1.standard_concept = 'S'
		AND COALESCE(checkid, 9) = 9

	UNION ALL*/

	--Rxnorm/Rxnorm Extension name duplications
	--tempopary disabled (never used)
	/*SELECT 9 check_id,
			c_int.concept_id_1,
			c_int.concept_id_2,
			'Concept replaced by' AS relationship_id,
			NULL AS valid_start_date,
			NULL AS valid_end_date,
			NULL AS invalid_reason
		FROM (
			SELECT FIRST_VALUE(c.concept_id) OVER (
					PARTITION BY d.concept_name ORDER BY c.vocabulary_id DESC,
						c.concept_name,
						c.concept_id
					) AS concept_id_1,
				c.concept_id AS concept_id_2,
				c.vocabulary_id
			FROM concept c
			JOIN (
				SELECT LOWER(concept_name) AS concept_name,
					concept_class_id
				FROM concept c_int
				WHERE c_int.vocabulary_id LIKE 'RxNorm%'
					AND c_int.concept_name NOT LIKE '%...%'
					AND c_int.invalid_reason IS NULL
				GROUP BY LOWER(c_int.concept_name),
					c_int.concept_class_id
				HAVING COUNT(*) > 1
				
				EXCEPT
				
				SELECT LOWER(c_int.concept_name),
					c_int.concept_class_id
				FROM concept c_int
				WHERE c_int.vocabulary_id = 'RxNorm'
					AND c_int.concept_name NOT LIKE '%...%'
					AND c_int.invalid_reason IS NULL
				GROUP BY LOWER(c_int.concept_name),
					c_int.concept_class_id
				HAVING COUNT(*) > 1
				) d ON LOWER(c.concept_name) = d.concept_name
				AND c.vocabulary_id LIKE 'RxNorm%'
				AND c.invalid_reason IS NULL
			) c_int
		JOIN concept c1 ON c1.concept_id = c_int.concept_id_1
		JOIN concept c2 ON c2.concept_id = c_int.concept_id_2
		WHERE c_int.concept_id_1 <> c_int.concept_id_2
			AND NOT (
				c1.vocabulary_id = 'RxNorm'
				AND c2.vocabulary_id = 'RxNorm'
				)
			--AVOF-1434 (20190125)
			AND NOT EXISTS (
				SELECT 1
				FROM drug_strength ds1,
					drug_strength ds2
				WHERE ds1.drug_concept_id = c1.concept_id
					AND ds2.drug_concept_id = c2.concept_id
					AND ds1.ingredient_concept_id = ds2.ingredient_concept_id
					AND ds1.amount_value = ds2.numerator_value
					AND ds1.amount_unit_concept_id = ds2.numerator_unit_concept_id
					AND ds1.amount_unit_concept_id IN (
						9325,
						9324
						)
				)
			AND COALESCE(checkid, 9) = 9

		UNION ALL*/
--one concept has multiple replaces
INSERT INTO icdoscript.QA_get_checks
SELECT 10 check_id,
	'one concept has multiple replaces' AS check_name,
	r.*
FROM icdoscript.concept_relationship r
WHERE (
		r.concept_id_1,
		r.relationship_id
		) IN (
		SELECT r_int.concept_id_1,
			r_int.relationship_id
		FROM icdoscript.concept_relationship r_int
		WHERE r_int.relationship_id IN (
				'Concept replaced by',
				'Concept same_as to',
				'Concept alt_to to',
				'Concept was_a to'
				)
			AND r_int.invalid_reason IS NULL
		GROUP BY r_int.concept_id_1,
			r_int.relationship_id
		HAVING COUNT(*) > 1
		)

--wrong concept_name [AVOF-1438]
INSERT INTO icdoscript.QA_get_checks
SELECT 11 check_id,
	'wrong concept_name ("OMOP generated", but should be OMOPxxx)' AS check_name,
	c.concept_id,
	NULL,
	c.vocabulary_id,
	c.valid_start_date,
	c.valid_end_date,
	c.invalid_reason
FROM icdoscript.concept c
WHERE c.domain_id <> 'Metadata'
	AND c.concept_code = 'OMOP generated'

--duplicate 'OMOP generated' concepts [AVOF-2000]
INSERT INTO icdoscript.QA_get_checks
SELECT 12 check_id,
	'duplicate ''OMOP generated'' concepts' AS check_name,
	s0.concept_id,
	NULL,
	s0.vocabulary_id,
	s0.valid_start_date,
	s0.valid_end_date,
	NULL
FROM (
	SELECT c.concept_id,
		c.vocabulary_id,
		c.valid_start_date,
		c.valid_end_date,
		COUNT(*) OVER (
			PARTITION BY c.concept_name,
			c.concept_code,
			c.vocabulary_id
			) AS cnt
	FROM icdoscript.concept c
	WHERE c.invalid_reason IS NULL
		AND c.concept_code = 'OMOP generated'
	) AS s0
WHERE s0.cnt > 1

--duplicate concept_name in 'OMOP Extension' vocabulary
INSERT INTO icdoscript.QA_get_checks
SELECT 13 check_id,
	'duplicate concept_name in ''OMOP Extension'' vocabulary: ' || s0.concept_name AS check_name,
	s0.concept_id,
	NULL,
	s0.vocabulary_id,
	s0.valid_start_date,
	s0.valid_end_date,
	s0.invalid_reason
FROM (
	SELECT c.concept_id,
		c.concept_name,
		c.vocabulary_id,
		c.valid_start_date,
		c.valid_end_date,
		c.invalid_reason,
		COUNT(c.concept_code) OVER (PARTITION BY LOWER(c.concept_name)) AS cnt
	FROM icdoscript.concept c
	WHERE c.vocabulary_id = 'OMOP Extension'
		AND c.invalid_reason IS NULL
	) s0
WHERE s0.cnt > 1