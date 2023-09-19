set search_path to dev;

raise notice 'Creating base table...';
CREATE TABLE temporary_ca_base$ AS
	SELECT r.concept_id_1 AS ancestor_concept_id,
		r.concept_id_2 AS descendant_concept_id,
		CASE 
			WHEN s.is_hierarchical = '1'
			AND c1.standard_concept IS NOT NULL
			THEN 1
		ELSE 0
		END AS levels_of_separation
FROM concept_relationship r
JOIN relationship s ON s.relationship_id = r.relationship_id
	AND s.defines_ancestry = '1'
JOIN concept c1 ON c1.concept_id = r.concept_id_1
	AND c1.invalid_reason IS NULL
JOIN concept c2 ON c2.concept_id = r.concept_id_2
	AND c2.invalid_reason IS NULL
WHERE r.invalid_reason IS NULL;

CREATE INDEX idx_temp_ca_base$ ON temporary_ca_base$ (ancestor_concept_id,descendant_concept_id,levels_of_separation) WITH (FILLFACTOR=100);
ANALYZE temporary_ca_base$;

--create a 'groups' table. we want to split a whole bunch of data into N separate chunks, this will give a good perfomance boost due to less temporary tablespace usage
raise notice 'Creating groups table...';
CREATE TABLE temporary_ca_groups$ AS
SELECT s1.n,
	COALESCE(LAG(s1.ancestor_concept_id) OVER (
			ORDER BY s1.n
			), - 1) ancestor_concept_id_min,
	ancestor_concept_id ancestor_concept_id_max
FROM (
	SELECT n,
		MAX(ancestor_concept_id) ancestor_concept_id
	FROM (
		SELECT NTILE(50) OVER (
				ORDER BY ancestor_concept_id
				) n,
			ancestor_concept_id
		FROM temporary_ca_base$
		) AS s0
	GROUP BY n
	) AS s1;


raise notice 'Creating temp Concept Ancestor...';
CREATE TABLE temporary_ca$ (LIKE concept_ancestor);

do $$

declare cRecord RECORD;

begin
	
	FOR cRecord IN (SELECT * FROM temporary_ca_groups$ ORDER BY n) LOOP
		INSERT INTO temporary_ca$
		WITH recursive hierarchy_concepts(ancestor_concept_id, descendant_concept_id, root_ancestor_concept_id, levels_of_separation, full_path) AS (
				SELECT ca.ancestor_concept_id,
					ca.descendant_concept_id,
					ca.ancestor_concept_id AS root_ancestor_concept_id,
					ca.levels_of_separation,
					ARRAY [descendant_concept_id] AS full_path
				FROM temporary_ca_base$ ca
				JOIN concept c ON c.concept_id = ca.ancestor_concept_id
					AND c.standard_concept IS NOT NULL --remove non-standard records in ancestor_concept_id
				WHERE ca.ancestor_concept_id > cRecord.ancestor_concept_id_min
					AND ca.ancestor_concept_id <= cRecord.ancestor_concept_id_max
				
				UNION ALL
				
				SELECT c.ancestor_concept_id,
					c.descendant_concept_id,
					root_ancestor_concept_id,
					hc.levels_of_separation + c.levels_of_separation AS levels_of_separation,
					hc.full_path || c.descendant_concept_id AS full_path
				FROM temporary_ca_base$ c
				JOIN hierarchy_concepts hc ON hc.descendant_concept_id = c.ancestor_concept_id
				WHERE c.descendant_concept_id <> ALL (full_path)
				)
		SELECT hc.root_ancestor_concept_id AS ancestor_concept_id,
			hc.descendant_concept_id,
			MIN(hc.levels_of_separation) AS min_levels_of_separation,
			MAX(hc.levels_of_separation) AS max_levels_of_separation
		FROM hierarchy_concepts hc
		GROUP BY hc.root_ancestor_concept_id,
			hc.descendant_concept_id;
	END LOOP;
end; $$


--remove non-standard records in descendant_concept_id
raise notice 'Removing non-standard records from temp table...';
DELETE
FROM temporary_ca$ ca USING concept c
WHERE c.standard_concept IS NULL
	AND c.concept_id = ca.descendant_concept_id;

--Add connections to self for those vocabs having at least one concept in the concept_relationship table
raise notice 'Adding connections to self...';
INSERT INTO temporary_ca$
SELECT c.concept_id AS ancestor_concept_id,
	c.concept_id AS descendant_concept_id,
	0 AS min_levels_of_separation,
	0 AS max_levels_of_separation
FROM concept c
WHERE c.vocabulary_id IN (
		SELECT c_int.vocabulary_id
		FROM concept_relationship cr,
			concept c_int
		WHERE c_int.concept_id = cr.concept_id_1
			AND cr.invalid_reason IS NULL
		)
	AND c.invalid_reason IS NULL
	AND c.standard_concept IS NOT NULL;

CREATE INDEX idx_tmp_ca$ ON temporary_ca$ (ancestor_concept_id, descendant_concept_id, min_levels_of_separation, max_levels_of_separation) WITH (FILLFACTOR=100);
ANALYZE temporary_ca$;

raise notice 'Adding new records to concept_ancestor...';
INSERT INTO dev.concept_ancestor (ancestor_concept_id, descendant_concept_id, min_levels_of_separation, max_levels_of_separation)
SELECT tca.ancestor_concept_id, tca.descendant_concept_id, tca.min_levels_of_separation, tca.max_levels_of_separation
FROM temporary_ca$ tca
WHERE NOT EXISTS (
    SELECT 1
    FROM concept_ancestor ca
    WHERE ca.ancestor_concept_id = tca.ancestor_concept_id
    AND ca.descendant_concept_id = tca.descendant_concept_id
);

-- Remove non-standard concepts from both concept columns
raise notice 'Removing non-standard concepts from Concept Ancestor...';
DELETE FROM concept_ancestor ca
WHERE ancestor_concept_id IN (
    select concept_id
    from (
    	SELECT *
    	FROM dev.concept
    	where standard_concept is null
    	or standard_concept = ''
    	EXCEPT 
    	SELECT * 
    	FROM prod.concept) c
);

DELETE FROM concept_ancestor ca
WHERE descendant_concept_id IN (
    select concept_id
    from (
    	SELECT *
    	FROM dev.concept
    	where standard_concept is null
    	or standard_concept = ''
    	EXCEPT 
    	SELECT * 
    	FROM prod.concept) c
);

drop table temporary_ca_groups$ cascade;
drop table temporary_ca_base$ cascade;
drop table temporary_ca$ cascade;





