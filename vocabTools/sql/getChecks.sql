set search_path to dev;

CREATE OR REPLACE FUNCTION dev.get_checks (checkid IN INT DEFAULT NULL)
RETURNS TABLE
(
	check_id int4,
	check_name VARCHAR(1000),
	concept_id_1 int4,
	concept_id_2 int4,
	relationship_id VARCHAR(20),
	valid_start_date DATE,
	valid_end_date DATE,
	invalid_reason VARCHAR(1)
)
AS $BODY$
	--relationships cycle
	SELECT 1 check_id,
		'relationships cycle' AS check_name,
		r.*
	FROM concept_relationship r,
		concept_relationship r_int
	WHERE r.invalid_reason IS NULL
		AND r_int.concept_id_1 = r.concept_id_2
		AND r_int.concept_id_2 = r.concept_id_1
		AND r.concept_id_1 <> r.concept_id_2
		AND r_int.relationship_id = r.relationship_id
		AND r_int.invalid_reason IS NULL
		AND COALESCE(checkid, 1) = 1

	UNION ALL

	--opposing relationships between same pair of concepts
	SELECT 2 check_id,
		'opposing relationships between same pair of concepts' AS check_name,
		r.*
	FROM concept_relationship r,
		concept_relationship r_int,
		relationship rel
	WHERE r.invalid_reason IS NULL
		AND r.relationship_id = rel.relationship_id
		AND r_int.concept_id_1 = r.concept_id_1
		AND r_int.concept_id_2 = r.concept_id_2
		AND r.concept_id_1 <> r.concept_id_2
		AND r_int.relationship_id = rel.reverse_relationship_id
		AND r_int.invalid_reason IS NULL
		AND COALESCE(checkid, 2) = 2

	UNION ALL

	--relationships without reverse
	SELECT 3 check_id,
		'relationships without reverse' AS check_name,
		r.*
	FROM concept_relationship r,
		relationship rel
	WHERE r.relationship_id = rel.relationship_id
		AND NOT EXISTS (
			SELECT 1
			FROM concept_relationship r_int
			WHERE r_int.relationship_id = rel.reverse_relationship_id
				AND r_int.concept_id_1 = r.concept_id_2
				AND r_int.concept_id_2 = r.concept_id_1
			)
		AND COALESCE(checkid, 3) = 3

	UNION ALL

	--wrong relationships: 'Maps to' to 'D' or 'U'; replacement relationships to 'D'
	SELECT 5 check_id, $$wrong relationships: 'Maps to' TO 'D' OR 'U'; replacement relationships TO 'D'$$ AS check_name,
		r.*
	FROM concept c2,
		concept_relationship r
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
		AND COALESCE(checkid, 5) = 5

	UNION ALL

	--direct and reverse mappings are not same
	SELECT 6 check_id,
		'direct and reverse mappings are not same' AS check_name,
		r.*
	FROM concept_relationship r,
		relationship rel,
		concept_relationship r_int
	WHERE r.relationship_id = rel.relationship_id
		AND r_int.relationship_id = rel.reverse_relationship_id
		AND r_int.concept_id_1 = r.concept_id_2
		AND r_int.concept_id_2 = r.concept_id_1
		AND (
			r.valid_end_date <> r_int.valid_end_date
			OR COALESCE(r.invalid_reason, 'X') <> COALESCE(r_int.invalid_reason, 'X')
			)
		AND COALESCE(checkid, 6) = 6

	UNION ALL

	--wrong valid_start_date, valid_end_date or invalid_reason for the concept
/*	SELECT 7 check_id,
		'wrong valid_start_date, valid_end_date or invalid_reason for the concept' AS check_name,
		c.concept_id,
		NULL,
		c.vocabulary_id,
		c.valid_start_date,
		c.valid_end_date,
		c.invalid_reason
	FROM concept c
	JOIN vocabulary_conversion vc ON vc.vocabulary_id_v5 = c.vocabulary_id
	WHERE (
			c.valid_end_date < c.valid_start_date
			OR (
				c.valid_end_date = TO_DATE('20991231', 'YYYYMMDD')
				AND c.invalid_reason IS NOT NULL
				)
			OR (
				c.valid_end_date <> TO_DATE('20991231', 'YYYYMMDD')
				AND c.invalid_reason IS NULL
				AND c.vocabulary_id NOT IN (SELECT TRIM(v) FROM UNNEST(STRING_TO_ARRAY((SELECT var_value FROM devv5.config$ WHERE var_name='special_vocabularies'),',')) v)
				)
			OR c.valid_start_date > COALESCE(vc.latest_update, CURRENT_DATE) + INTERVAL '15 year' --some concepts might be from near future (e.g. GGR, HCPCS) [AVOF-1015]/increased 20180928 for some NDC concepts
			OR c.valid_start_date < TO_DATE('19000101', 'yyyymmdd') -- some concepts have a real date < 1970
			)
		AND COALESCE(checkid, 7) = 7

	UNION ALL

	--wrong valid_start_date, valid_end_date or invalid_reason for the concept_relationship
	SELECT 8 check_id,
		'wrong valid_start_date, valid_end_date or invalid_reason for the concept_relationship' AS check_name,
		s0.concept_id_1,
		s0.concept_id_2,
		s0.relationship_id,
		s0.valid_start_date,
		s0.valid_end_date,
		s0.invalid_reason
	FROM (
		SELECT r.*,
			CASE 
				WHEN (
						r.valid_end_date = TO_DATE('20991231', 'YYYYMMDD')
						AND r.invalid_reason IS NOT NULL
						)
					OR (
						r.valid_end_date <> TO_DATE('20991231', 'YYYYMMDD')
						AND r.invalid_reason IS NULL
						)
					OR (
						r.valid_start_date > CURRENT_DATE
						AND r.valid_start_date IS DISTINCT FROM GREATEST(vc1.latest_update, vc2.latest_update)
						)
					OR r.valid_start_date < TO_DATE('19700101', 'yyyymmdd')
					THEN 1
				ELSE 0
				END check_flag
		FROM concept_relationship r
		JOIN concept c1 ON c1.concept_id = r.concept_id_1
		JOIN concept c2 ON c2.concept_id = r.concept_id_2
		LEFT JOIN vocabulary_conversion vc1 ON vc1.vocabulary_id_v5 = c1.vocabulary_id
		LEFT JOIN vocabulary_conversion vc2 ON vc2.vocabulary_id_v5 = c2.vocabulary_id
		) AS s0
	WHERE check_flag = 1
		AND COALESCE(checkid, 8) = 8

	UNION ALL
*/
	--one concept has multiple replaces
	SELECT 10 check_id,
		'one concept has multiple replaces' AS check_name,
		r.*
	FROM concept_relationship r
	WHERE (
			r.concept_id_1,
			r.relationship_id
			) IN (
			SELECT r_int.concept_id_1,
				r_int.relationship_id
			FROM concept_relationship r_int
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
		AND COALESCE(checkid, 10) = 10

	UNION ALL

	--wrong concept_name [AVOF-1438]
	SELECT 11 check_id,
		'wrong concept_name ("OMOP generated", but should be OMOPxxx)' AS check_name,
		c.concept_id,
		NULL,
		c.vocabulary_id,
		c.valid_start_date,
		c.valid_end_date,
		c.invalid_reason
	FROM concept c
	WHERE c.domain_id <> 'Metadata'
		AND c.concept_code = 'OMOP generated'
		AND COALESCE(checkid, 11) = 11

	UNION ALL

	--duplicate 'OMOP generated' concepts [AVOF-2000]
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
		FROM concept c
		WHERE c.invalid_reason IS NULL
			AND c.concept_code = 'OMOP generated'
		) AS s0
	WHERE s0.cnt > 1
		AND COALESCE(checkid, 12) = 12

	UNION ALL

	--duplicate concept_name in 'OMOP Extension' vocabulary
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
		FROM concept c
		WHERE c.vocabulary_id = 'OMOP Extension'
			AND c.invalid_reason IS NULL
		) s0
	WHERE s0.cnt > 1
		AND COALESCE(checkid, 13) = 13;

$BODY$
LANGUAGE 'sql' STABLE PARALLEL RESTRICTED SECURITY INVOKER;

select * from dev.get_checks()