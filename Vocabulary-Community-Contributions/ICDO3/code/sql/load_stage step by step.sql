-- In Postgres
-- Line 36 - 103
-- 3.1. Building SNOMED hierarchy to pick future mapping targets
-- Step 1: get status on date of interest of each concept (active or not active)
DROP TABLE IF EXISTS icdoscript.active_concept;
CREATE TABLE icdoscript.active_concept AS (
    SELECT DISTINCT
      c.id,
      FIRST_VALUE(c.active) OVER (PARTITION BY c.id ORDER BY c.effectivetime DESC) AS active
    FROM snomedct.concept_f AS c
    WHERE c.effectivetime <= TO_DATE('20211124','YYYYMMDD')
)
-- Step 2: get all 'is a' relationships between active concepts determined in previous steps and get status of relationship on date of interest
DROP TABLE IF EXISTS icdoscript.active_status;
CREATE TABLE icdoscript.active_status AS (
    SELECT DISTINCT
      r.sourceid,
      r.destinationid,
      FIRST_VALUE(r.active) OVER (PARTITION BY r.id ORDER BY r.effectivetime DESC) AS active
    FROM snomedct.relationship_f AS r
    JOIN icdoscript.active_concept AS a1
      ON a1.id = r.sourceid AND a1.active = 1::bit
    JOIN icdoscript.active_concept AS a2
      ON a2.id = r.destinationid AND a2.active = 1::bit
    WHERE r.typeid = 116680003 AND r.effectivetime <= TO_DATE('20211124','YYYYMMDD')
)
-- Step 3: only select the active relationships
DROP TABLE IF EXISTS icdoscript.concepts;
CREATE TABLE icdoscript.concepts AS (
	SELECT
		destinationid AS ancestor_concept_code,
		sourceid AS descendant_concept_code
	FROM icdoscript.active_status
	WHERE active = 1::bit
) 
-- Step 4
DROP TABLE IF EXISTS icdoscript.hierarchy_concepts;
CREATE TABLE icdoscript.hierarchy_concepts AS (
	WITH RECURSIVE hierarchy_concepts(ancestor_concept_code, descendant_concept_code, root_ancestor_concept_code, full_path) AS (
		SELECT ancestor_concept_code,
			descendant_concept_code,
			ancestor_concept_code AS root_ancestor_concept_code,
			ARRAY [descendant_concept_code::TEXT] AS full_path
		FROM icdoscript.concepts
		
		UNION ALL
		
		SELECT c.ancestor_concept_code,
			c.descendant_concept_code,
			root_ancestor_concept_code,
			hc.full_path || c.descendant_concept_code::TEXT AS full_path
		FROM icdoscript.concepts c
		JOIN hierarchy_concepts hc ON hc.descendant_concept_code = c.ancestor_concept_code
		WHERE c.descendant_concept_code::TEXT <> ALL (full_path)
		)
	SELECT 
		hc.ancestor_concept_code AS ancestor_concept_code,
		hc.descendant_concept_code AS descendant_concept_code,
		hc.root_ancestor_concept_code AS root_ancestor_concept_code,
		hc.full_path AS full_path
	FROM hierarchy_concepts hc
)
-- Step 5
DROP TABLE IF EXISTS icdoscript.snomed_ancestor;
CREATE TABLE icdoscript.snomed_ancestor AS (
	SELECT DISTINCT
		descendant_concept_code AS descendant_concept_code,
		root_ancestor_concept_code AS ancestor_concept_code 
	FROM icdoscript.hierarchy_concepts
)
-- Line 104-110
--3.2. Add relation to self for each target
INSERT INTO icdoscript.snomed_ancestor
SELECT DISTINCT
  descendant_concept_code AS descendant_concept_code,
  descendant_concept_code AS ancestor_concept_code 
FROM icdoscript.snomed_ancestor hc
-- Line 111-143
-- First load r_to_c_all
DROP TABLE IF EXISTS icdoscript.r_to_c_all CASCADE;
CREATE TABLE icdoscript.r_to_c_all(
  concept_code VARCHAR(50) NOT NULL,
  concept_name VARCHAR(255) NOT NULL,	
  relationship_id VARCHAR(20) NOT NULL,	
  snomed_code BIGINT NOT NULL, 
  precedence INT
)
TRUNCATE TABLE icdoscript.r_to_c_all;
COPY icdoscript.r_to_c_all FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/r_to_c_all.csv' CSV
DELIMITER E'\t' HEADER QUOTE '"'
ENCODING 'UTF8';
--3.3. Add missing relation to Primary Malignant Neoplasm where needed
INSERT INTO icdoscript.snomed_ancestor (ancestor_concept_code, descendant_concept_code)
SELECT DISTINCT 86049000, snomed_code
FROM icdoscript.r_to_c_all r
WHERE
  r.concept_code ~ '\d{4}\/3' AND
  r.relationship_id = 'Maps to' AND
  NOT EXISTS
  (
    SELECT 1
    FROM icdoscript.snomed_ancestor a
    WHERE a.ancestor_concept_code = 86049000 AND a.descendant_concept_code = r.snomed_code --PMN
   ) 
ALTER TABLE icdoscript.snomed_ancestor ADD CONSTRAINT xpksnomed_ancestor PRIMARY KEY (ancestor_concept_code,descendant_concept_code);
CREATE INDEX snomed_ancestor_d on icdoscript.snomed_ancestor (descendant_concept_code);
ANALYZE icdoscript.snomed_ancestor;
-- Line 144-176: creates the histology mapping between ICDO3 and SNOMED
--4. Prepare updates for histology mapping from SNOMED refset
DROP TABLE IF EXISTS icdoscript.snomed_mapping;
CREATE TABLE icdoscript.snomed_mapping AS
SELECT DISTINCT
  referencedcomponentid as snomed_code,
  maptarget AS icdo_code
FROM snomedct.simplemaprefset_f AS smr
JOIN icdoscript.active_concept AS ac
  ON ac.id = smr.referencedcomponentid AND ac.active = 1::bit
-- filter out new sources, as SNOMED update could have been delayed
WHERE smr.effectivetime <= TO_DATE('20211124','YYYYMMDD') and smr.refsetid = 446608001 and smr.active = 1::bit and smr.maptarget like '%/%'
-- Line 177-189: The SNOMED mapping contains mappings of different SNOMED concepts to the same ICDO3 histology: pick the one highest in the hierarchy
-- (descendants are automatically the same histology, ancestors are not)
--5. Remove descendants where ancestor is specified as mapping target
DELETE FROM icdoscript.snomed_mapping m1
WHERE EXISTS
(
  SELECT
  FROM icdoscript.snomed_mapping m2
  JOIN icdoscript.snomed_ancestor a 
    ON a.ancestor_concept_code != a.descendant_concept_code AND a.descendant_concept_code = m1.snomed_code
	AND a.ancestor_concept_code = m2.snomed_code AND m2.icdo_code = m1.icdo_code
)
-- Line 190-199: Ambiguous mappings are removed (quite a lot!!!)
--6. Remove ambiguous mappings
DELETE FROM icdoscript.snomed_mapping
WHERE icdo_code IN
(
  SELECT icdo_code
  FROM icdoscript.snomed_mapping
  GROUP BY icdo_code
  HAVING COUNT(1) > 1
)
-- Line 200-214: Update the manual mappings in r_to_c_all with mappings from SNOMED refset.
--7. Update mappings
--7.1. Histology mappings from SNOMED International refset
UPDATE icdoscript.r_to_c_all r
SET
  relationship_id = 'Maps to',
  snomed_code = 
  (
    SELECT 
	  s.snomed_code
    FROM icdoscript.snomed_mapping s
    WHERE r.concept_code = s.icdo_code
  )
WHERE r.concept_code IN (SELECT s.icdo_code FROM icdoscript.snomed_mapping s) AND r.precedence IS NULL -- no automated modification for concepts with alternating mappings
-- Line 215-238: Update deprecated SNOMED codes with valid ones.
--7.2. Deprecated concepts with replacement
WITH replacement AS
(
  SELECT 
    r.concept_code, 
	r.snomed_code AS old_code, 
	c2.concept_code AS new_code
  FROM icdoscript.r_to_c_all r
  JOIN omopcdm.concept c 
    ON c.concept_code = snomed_code::text AND c.vocabulary_id = 'SNOMED' AND c.invalid_reason = 'U'
  JOIN omopcdm.concept_relationship x 
    ON x.concept_id_1 = c.concept_id AND x.relationship_id = 'Maps to' AND x.invalid_reason IS NULL 
  JOIN omopcdm.concept c2 
    ON c2.concept_id = x.concept_id_2
)
UPDATE icdoscript.r_to_c_all a
SET snomed_code = new_code::bigint
FROM replacement x
WHERE a.concept_code = x.concept_code AND x.old_code = a.snomed_code AND a.precedence IS NULL -- no automated modification for concepts with alternating mappings
-- Line 239-251: Remove duplicate mappings (none)
--8. Remove duplications
DELETE FROM icdoscript.r_to_c_all r1
WHERE EXISTS
(
  SELECT
  FROM icdoscript.r_to_c_all r2
  WHERE r1.concept_code = r2.concept_code AND r2.snomed_code = r1.snomed_code AND r2.ctid < r1.ctid
) 
AND r1.precedence IS NULL -- no automated modification for concepts with alternating mappings
-- Line 252-253: Delete 9999/9 (one entry)
--9. Preserve missing morphology mapped to generic neoplasm
DELETE FROM icdoscript.r_to_c_all WHERE concept_code = '9999/9'
-- Line 255-268: 
--Code 9999/9 must NOT be encountered in final tables and should be removed during post-processing 
INSERT INTO icdoscript.r_to_c_all
VALUES ('9999/9','Unknown histology','Maps to','108369006') --Neoplasm
CREATE INDEX IF NOT EXISTS rtca_target_vc on icdoscript.r_to_c_all (snomed_code)
ANALYZE icdoscript.r_to_c_all
