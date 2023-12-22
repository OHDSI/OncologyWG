-- Running the script takes ~16 minutes
-- In Postgres
-- First create staging tables
-- From Vocabulary-v5.0/working/DevV5_DDL.sql
DROP TABLE IF EXISTS icdoscript.concept_stage;
CREATE TABLE icdoscript.concept_stage (
	concept_id int4,
	concept_name VARCHAR (255),
	domain_id VARCHAR (20),
	vocabulary_id VARCHAR (20) NOT NULL,
	concept_class_id VARCHAR (20),
	standard_concept VARCHAR (1),
	concept_code VARCHAR (50) NOT NULL,
	valid_start_date DATE NOT NULL,
	valid_end_date DATE NOT NULL,
	invalid_reason VARCHAR (1)
);
DROP TABLE IF EXISTS icdoscript.concept_relationship_stage;
CREATE TABLE icdoscript.concept_relationship_stage (
	concept_id_1 int4,
	concept_id_2 int4,
	concept_code_1 VARCHAR (50) NOT NULL,
	concept_code_2 VARCHAR (50) NOT NULL,
	vocabulary_id_1 VARCHAR (20) NOT NULL,
	vocabulary_id_2 VARCHAR (20) NOT NULL,
	relationship_id VARCHAR (20) NOT NULL,
	valid_start_date DATE NOT NULL,
	valid_end_date DATE NOT NULL,
	invalid_reason VARCHAR (1)
);
DROP TABLE IF EXISTS icdoscript.concept_synonym_stage;
CREATE TABLE icdoscript.concept_synonym_stage (
	synonym_concept_id int4,
	synonym_name VARCHAR (1000) NOT NULL,
	synonym_concept_code VARCHAR (50) NOT NULL,
	synonym_vocabulary_id VARCHAR (20) NOT NULL,
	language_concept_id int4 NOT NULL
);
DROP TABLE IF EXISTS icdoscript.pack_content_stage;
CREATE TABLE icdoscript.pack_content_stage (
	pack_concept_code VARCHAR (20) NOT NULL,
	pack_vocabulary_id VARCHAR (20) NOT NULL,
	drug_concept_code VARCHAR (20) NOT NULL,
	drug_vocabulary_id VARCHAR (20) NOT NULL,
	amount int2,
	box_size int2
);
DROP TABLE IF EXISTS icdoscript.drug_strength_stage;
CREATE TABLE icdoscript.drug_strength_stage (
	drug_concept_code VARCHAR (20) NOT NULL,
	vocabulary_id_1 VARCHAR (20) NOT NULL,
	ingredient_concept_code VARCHAR (20) NOT NULL,
	vocabulary_id_2 VARCHAR (20) NOT NULL,
	amount_value NUMERIC,
	amount_unit_concept_id int4,
	numerator_value NUMERIC,
	numerator_unit_concept_id int4,
	denominator_value NUMERIC,
	denominator_unit_concept_id int4,
	valid_start_date DATE NOT NULL,
	valid_end_date DATE NOT NULL,
	invalid_reason VARCHAR (1)
);
-- Load input files:
-- r_to_c_all
DROP TABLE IF EXISTS sources.r_to_c_all CASCADE;
CREATE TABLE sources.r_to_c_all(
  concept_code VARCHAR(50) NOT NULL,
  concept_name VARCHAR(255) NOT NULL,	
  relationship_id VARCHAR(20) NOT NULL,	
  snomed_code BIGINT NOT NULL, 
  precedence INT
);
TRUNCATE TABLE sources.r_to_c_all;
--COPY sources.r_to_c_all FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/r_to_c_all.csv' CSV
COPY sources.r_to_c_all FROM 'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/updated input files jan24 release/r_to_c_all.csv' CSV
DELIMITER E'\t' HEADER QUOTE '"'
ENCODING 'UTF8';
-- topo_source_iacr: check if there is a newer file
DROP TABLE IF EXISTS sources.topo_source_iacr CASCADE;
CREATE TABLE sources.topo_source_iacr(
  source_string VARCHAR(255),
  code VARCHAR(50),
  concept_name VARCHAR(255)	
);
TRUNCATE TABLE sources.topo_source_iacr;
COPY sources.topo_source_iacr FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/topo_source_iacr.csv' CSV
DELIMITER ',' HEADER QUOTE ''''
ENCODING 'UTF8';
-- morph_source_who
DROP TABLE IF EXISTS sources.morph_source_who CASCADE;
CREATE TABLE sources.morph_source_who(
  icdo32 VARCHAR(50),
  level VARCHAR(50),
  term VARCHAR(255),
  code_reference VARCHAR(50),
  obs VARCHAR(50)
);
TRUNCATE TABLE sources.morph_source_who;
COPY sources.morph_source_who FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/morph_source_who.csv' CSV
DELIMITER ',' HEADER QUOTE ''''
ENCODING 'UTF8';
-- concept_manual
DROP TABLE IF EXISTS sources.concept_manual CASCADE;
CREATE TABLE sources.concept_manual(
  concept_name VARCHAR(255),
  DOMAIN_ID VARCHAR(20),
  VOCABULARY_ID VARCHAR(20) NOT NULL,
  CONCEPT_CLASS_ID VARCHAR(20),
  STANDARD_CONCEPT VARCHAR(1),
  concept_code VARCHAR(50) NOT NULL,
  VALID_START_DATE DATE NOT NULL,
  VALID_END_DATE DATE,
  INVALID_REASON VARCHAR(1)
);
TRUNCATE TABLE sources.concept_manual;
COPY sources.concept_manual FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/concept_manual.csv' CSV
DELIMITER E'\t' HEADER QUOTE '"'
ENCODING 'UTF8';
-- icdo3_valid_combination
DROP TABLE IF EXISTS sources.icdo3_valid_combination CASCADE;
CREATE TABLE sources.icdo3_valid_combination(
  histology_behavior VARCHAR(10),
  site VARCHAR(10)
);
TRUNCATE TABLE sources.icdo3_valid_combination;
-- COPY sources.icdo3_valid_combination FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/icdo3_valid_combination.csv' CSV
COPY sources.icdo3_valid_combination FROM 'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/updated input files jan24 release/icdo3_valid_combination.csv' CSV
DELIMITER ',' HEADER QUOTE ''''
ENCODING 'UTF8';
-- concept_relationship_manual
DROP TABLE IF EXISTS  sources.concept_relationship_manual;
CREATE TABLE  sources.concept_relationship_manual (
  concept_code_1 varchar(50) NOT NULL,
  concept_code_2 varchar(50) NOT NULL,
  vocabulary_id_1 varchar(20) NOT NULL,
  vocabulary_id_2 varchar(20) NOT NULL,
  relationship_id varchar(20) NOT NULL,
  valid_start_date date NOT NULL,
  valid_end_date date NOT NULL,
  invalid_reason varchar(1) NULL 
);
TRUNCATE TABLE sources.concept_relationship_manual;
--COPY sources.concept_relationship_manual FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/concept_relationship_manual.csv' CSV
COPY sources.concept_relationship_manual FROM 'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/updated input files jan24 release/concept_relationship_manual.csv' CSV
DELIMITER E'\t' HEADER QUOTE '"'
ENCODING 'UTF8';
---- new_valid_combination
--DROP TABLE IF EXISTS sources.new_valid_combination CASCADE;
--CREATE TABLE sources.new_valid_combination(
--  histology_behavior VARCHAR(10),
--  site VARCHAR(10)
--);
--TRUNCATE TABLE sources.new_valid_combination;
--COPY sources.new_valid_combination FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/custom_sarcoma_codes.csv' CSV
--DELIMITER ',' HEADER QUOTE ''''
--ENCODING 'UTF8';
---- add to icdo3_valid_combination
--INSERT INTO sources.icdo3_valid_combination
--SELECT *
--FROM sources.new_valid_combination;
-- 1. Vocabulary update routine
-- Date determined by source: check SEER (check also if changed). But there will also be a version of the other ICDO3 codes we add. Probably using freezing date of community contributions.
-- First define the function (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/vocabulary_pack/CheckReplacementMappings.sql)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION SetLatestUpdate (
  pvocabularyname varchar,
  pvocabularydate date,
  pvocabularyversion varchar,
  pvocabularydevschema varchar,
  pappendvocabulary boolean = false
)
RETURNS void AS
$body$
    /*
     Adds (if not exists) column 'latest_update' to 'vocabulary' table and sets it to pVocabularyDate value
     Also adds 'dev_schema_name' column what needs for 'ProcessManualRelationships' procedure
     If pAppendVocabulary is set to TRUE, then procedure DOES NOT drops any columns, just updates the 'latest_update' and 'dev_schema_name'
    */
DECLARE
  z int4;
BEGIN
  IF pVocabularyName IS NULL
    THEN
    RAISE EXCEPTION 'pVocabularyName cannot be empty!';
  END IF;

  IF pVocabularyDate IS NULL
    THEN
    RAISE EXCEPTION 'pVocabularyDate cannot be empty!';
  END IF;

  /*IF pVocabularyDate > CURRENT_DATE
    THEN
    RAISE EXCEPTION 'pVocabularyDate bigger than current date!';
  END IF;*/ --disabled 20200713, e.g. ICD10CM may be from the 'future'

  IF pVocabularyVersion IS NULL
    THEN
    RAISE EXCEPTION 'pVocabularyVersion cannot be empty!';
  END IF;

  IF pVocabularyDevSchema IS NULL
    THEN
    RAISE EXCEPTION 'pVocabularyDevSchema cannot be empty!';
  END IF;
  SELECT COUNT(*)
  INTO z
  FROM omopcdm_jan24.vocabulary
  WHERE vocabulary_id = pVocabularyName;

  IF z = 0
    THEN
    RAISE EXCEPTION 'Vocabulary with id=% not found', pVocabularyName;
  END IF;
--  SELECT COUNT(*)
--  INTO z
--  FROM information_schema.schemata
--  WHERE schema_name = LOWER(pVocabularyDevSchema);
--
--  IF z = 0
--    THEN
--    RAISE EXCEPTION  'Dev schema with name % not found', pVocabularyDevSchema;
--  END IF;

  IF NOT pAppendVocabulary
    THEN
    ALTER TABLE omopcdm_jan24.vocabulary ADD
  if not exists latest_update DATE, add
  if not exists dev_schema_name VARCHAR(
        100);
    update omopcdm_jan24.vocabulary
    set latest_update = null,
        dev_schema_name = null;
  END IF;
  UPDATE omopcdm_jan24.vocabulary
  SET latest_update = pVocabularyDate,
      vocabulary_version = pVocabularyVersion,
      dev_schema_name = pVocabularyDevSchema
  WHERE vocabulary_id = pVocabularyName;
  
  ANALYZE omopcdm_jan24.vocabulary;--other queries will be able to use the index if it is linked to the vocabulary_id field from this table, e.g. select * from concept c join vocabulary v using (vocabulary_id) where v.latest_update is not null;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100
SET client_min_messages = error;
-- Then
DO $_$
BEGIN
	PERFORM SetLatestUpdate(
	pVocabularyName			=> 'ICDO3',
	pVocabularyDate			=> TO_DATE ('20231129', 'yyyymmdd'), 
	pVocabularyVersion		=> 'ICDO3 SEER Site/Histology Released 06/2020 + IARC likely and PathCHART valid conditions',
	pVocabularyDevSchema	=> 'DEV_icdo3'
);
END $_$
;
-- Line 31 - 33
-- 2. Initial cleanup
TRUNCATE TABLE icdoscript.concept_stage, icdoscript.concept_relationship_stage, icdoscript.concept_synonym_stage; -- icdoscript.drug_strength_stage, icdoscript.pack_content_stage;
-- Line 34 - 103
-- 3.1. Building SNOMED hierarchy to pick future mapping targets (you can't use OMOPCDM relations because SNOMED not always standard).
-- Step 1: get status on date of interest of each concept (active or not active)
DROP TABLE IF EXISTS icdoscript.active_concept;
CREATE TABLE icdoscript.active_concept AS (
    SELECT DISTINCT
      c.id,
      FIRST_VALUE(c.active) OVER (PARTITION BY c.id ORDER BY c.effectivetime DESC) AS active
    FROM snomed.sct2_concept_full_merged AS c
-- PICK DATE
    WHERE TO_DATE(c.effectivetime :: varchar, 'yyyymmdd') <= (SELECT TO_DATE(SUBSTRING(vocabulary_version FROM 78 FOR 10),'yyyy-mm-dd') FROM omopcdm_jan24.vocabulary WHERE vocabulary_id = 'SNOMED')
--	WHERE TO_DATE(c.effectivetime :: varchar, 'yyyymmdd') <= TO_DATE('20200620', 'yyyymmdd')
);
-- Step 2: get all 'is a' relationships between active concepts determined in previous steps and get status of relationship on date of interest
DROP TABLE IF EXISTS icdoscript.active_status;
CREATE TABLE icdoscript.active_status AS (
    SELECT DISTINCT
      r.sourceid,
      r.destinationid,
      FIRST_VALUE(r.active) OVER (PARTITION BY r.id ORDER BY r.effectivetime DESC) AS active
    FROM snomed.sct2_rela_full_merged AS r
    JOIN icdoscript.active_concept AS a1
      ON a1.id = r.sourceid AND a1.active = 1
    JOIN icdoscript.active_concept AS a2
      ON a2.id = r.destinationid AND a2.active = 1
-- PICK DATE	  
    WHERE r.typeid = 116680003 AND TO_DATE(r.effectivetime :: varchar, 'yyyymmdd') <= (SELECT TO_DATE(SUBSTRING(vocabulary_version FROM 78 FOR 10),'yyyy-mm-dd') FROM omopcdm_jan24.vocabulary WHERE vocabulary_id = 'SNOMED')
--	WHERE r.typeid = 116680003 AND TO_DATE(r.effectivetime :: varchar, 'yyyymmdd') <= TO_DATE('20200620', 'yyyymmdd')
);
-- Step 3: only select the active relationships
DROP TABLE IF EXISTS icdoscript.concepts;
CREATE TABLE icdoscript.concepts AS (
	SELECT
		destinationid AS ancestor_concept_code,
		sourceid AS descendant_concept_code
	FROM icdoscript.active_status
	WHERE active = 1
);
-- Step 4: takes ~5 minutes -> rewrite possible (doesn't seem so)
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
);
-- Step 5: Results in table icdoscript.snomed_ancestor with 10,719,149 rows
DROP TABLE IF EXISTS icdoscript.snomed_ancestor;
CREATE TABLE icdoscript.snomed_ancestor AS (
	SELECT DISTINCT
		descendant_concept_code AS descendant_concept_code,
		root_ancestor_concept_code AS ancestor_concept_code 
	FROM icdoscript.hierarchy_concepts
);
-- Clean up
DROP TABLE IF EXISTS icdoscript.active_status, icdoscript.concepts, icdoscript.hierarchy_concepts;
-- Line 104-110: Results in table icdoscript.snomed_ancestor with 11,510,673 rows (added 791,524 rows)
--3.2. Add relation to self for each target
INSERT INTO icdoscript.snomed_ancestor
SELECT DISTINCT
  descendant_concept_code AS descendant_concept_code,
  descendant_concept_code AS ancestor_concept_code 
FROM icdoscript.snomed_ancestor hc;
-- Line 111-143: Potentially also add /0, /1, /2 but now only /3 done because there the issue is the biggest (most missing relationships).
--3.3. Add missing relation to Primary Malignant Neoplasm where needed: everything that is not explicitly primary or secondary is assumed primary (otherwise hierarchy is very small).
-- First: Results in table icdoscript.snomed_ancestor with 10,964,704 rows (added 172 rows)
-- !!! r_to_c_all contains 204 inactive concepts (and 1762 active ones)!
SELECT a.active, COUNT(*)
FROM sources.r_to_c_all r
JOIN icdoscript.active_concept a
ON a.id = r.snomed_code
GROUP BY a.active;
-- This adds 643 rows to snomed_ancestor (total now 11,511,316)
INSERT INTO icdoscript.snomed_ancestor (ancestor_concept_code, descendant_concept_code)
SELECT DISTINCT 1240414004, snomed_code
FROM sources.r_to_c_all r
WHERE
  r.concept_code ~ '\d{4}\/3' AND
  r.relationship_id = 'Maps to' AND
  NOT EXISTS
  (
    SELECT 1
    FROM icdoscript.snomed_ancestor a
    WHERE a.ancestor_concept_code = 1240414004 AND a.descendant_concept_code = r.snomed_code --PMN
   );
-- !!! 86 now have an inactive descendant
SELECT a.active, COUNT(*)
FROM icdoscript.snomed_ancestor s
JOIN icdoscript.active_concept a
ON a.id = s.descendant_concept_code
GROUP BY a.active;
-- !!! 643 have an inactive ancestor because 1240414004 is not active anymore (since 30112022)
-- Then:
ALTER TABLE icdoscript.snomed_ancestor ADD CONSTRAINT xpksnomed_ancestor PRIMARY KEY (ancestor_concept_code,descendant_concept_code);
CREATE INDEX snomed_ancestor_d on icdoscript.snomed_ancestor (descendant_concept_code);
ANALYZE icdoscript.snomed_ancestor;
-- Line 144-176: creates the histology mapping between ICDO3 and SNOMED
-- Results in table icdoscript.snomed_mapping with 1633 rows 
--4. Prepare updates for histology mapping from SNOMED refset
DROP TABLE IF EXISTS icdoscript.snomed_mapping;
CREATE TABLE icdoscript.snomed_mapping AS
SELECT DISTINCT
  referencedcomponentid as snomed_code,
  maptarget AS icdo_code
FROM snomed.der2_srefset_simplemapfull_int AS smr
JOIN icdoscript.active_concept AS ac
  ON ac.id = smr.referencedcomponentid AND ac.active = 1
-- filter out new sources, as SNOMED update could have been delayed
-- PICK DATE
WHERE TO_DATE(smr.effectivetime :: varchar, 'yyyymmdd') <= (SELECT TO_DATE(SUBSTRING(vocabulary_version FROM 78 FOR 10),'yyyy-mm-dd') FROM omopcdm_jan24.vocabulary WHERE vocabulary_id = 'SNOMED') 
--WHERE TO_DATE(smr.effectivetime :: varchar, 'yyyymmdd') <= TO_DATE('20200620', 'yyyymmdd') 
  AND smr.refsetid = 446608001 AND smr.active = 1 AND smr.maptarget LIKE '%/%';
-- Line 177-189: The SNOMED mapping contains mappings of different SNOMED concepts to the same ICDO3 histology: pick the one highest in the hierarchy
-- (descendants are automatically the same histology, ancestors are not)
--5. Remove descendants where ancestor is specified as mapping target
-- Deletes 418 entries. Results in table icdoscript.snomed_mapping with 1236 rows.
DELETE FROM icdoscript.snomed_mapping m1
WHERE EXISTS
(
  SELECT
  FROM icdoscript.snomed_mapping m2
  JOIN icdoscript.snomed_ancestor a 
    ON a.ancestor_concept_code != a.descendant_concept_code AND a.descendant_concept_code = m1.snomed_code
	AND a.ancestor_concept_code = m2.snomed_code AND m2.icdo_code = m1.icdo_code
);
-- Line 190-199: Ambiguous mappings are removed (quite a lot!!!) --> check should not be too many!
--6. Remove ambiguous mappings
-- Ambiguous mappings:
SELECT icdo_code
FROM icdoscript.snomed_mapping
WHERE icdo_code IN
(
  SELECT icdo_code
  FROM icdoscript.snomed_mapping
  GROUP BY icdo_code
  HAVING COUNT(1) > 1
)
GROUP BY icdo_code
ORDER BY icdo_code;
-- Deletes 186 entries (78 ICDO3 codes). Results in table icdoscript.snomed_mapping with 1029 rows.
DELETE FROM icdoscript.snomed_mapping
WHERE icdo_code IN
(
  SELECT icdo_code
  FROM icdoscript.snomed_mapping
  GROUP BY icdo_code
  HAVING COUNT(1) > 1
);
-- Line 200-214: Update the manual mappings in r_to_c_all with mappings from SNOMED refset.
--7. Update mappings
--7.1. Histology mappings from SNOMED International refset
-- r_to_c_all contains 204 inactive concepts!
SELECT a.active, COUNT(*)
FROM sources.r_to_c_all r
JOIN icdoscript.active_concept a
ON a.id = r.snomed_code
GROUP BY a.active;
-- r_to_c_all has 1969 rows: these stay the same but mappings may be updated (983 in total)
UPDATE sources.r_to_c_all r
SET
  relationship_id = 'Maps to',
  snomed_code = 
  (
    SELECT 
	  s.snomed_code
    FROM icdoscript.snomed_mapping s
    WHERE r.concept_code = s.icdo_code
  )
WHERE r.concept_code IN (SELECT s.icdo_code FROM icdoscript.snomed_mapping s) AND r.precedence IS NULL; -- no automated modification for concepts with alternating mappings
-- r_to_c_all now has 163 inactive concepts!
SELECT a.active, COUNT(*)
FROM sources.r_to_c_all r
JOIN icdoscript.active_concept a
ON a.id = r.snomed_code
GROUP BY a.active;
-- Line 215-238: Update deprecated SNOMED codes with valid ones.
--7.2. Deprecated concepts with replacement
-- !!! We need an updated SNOMED here.
WITH replacement AS
(
  SELECT 
    r.concept_code, 
	r.snomed_code AS old_code, 
	c2.concept_code AS new_code
  FROM sources.r_to_c_all r
  JOIN omopcdm_jan24.concept c 
    ON c.concept_code = snomed_code::text AND c.vocabulary_id = 'SNOMED' AND c.invalid_reason = 'U'
  JOIN omopcdm_jan24.concept_relationship x 
    ON x.concept_id_1 = c.concept_id AND x.relationship_id = 'Maps to' AND x.invalid_reason IS NULL 
  JOIN omopcdm_jan24.concept c2 
    ON c2.concept_id = x.concept_id_2
)
UPDATE sources.r_to_c_all a
SET snomed_code = new_code::bigint
FROM replacement x
WHERE a.concept_code = x.concept_code AND x.old_code = a.snomed_code AND a.precedence IS NULL; -- no automated modification for concepts with alternating mappings
-- Line 239-251: Remove duplicate mappings (none)
--8. Remove duplications
DELETE FROM sources.r_to_c_all r1
WHERE EXISTS
(
  SELECT
  FROM sources.r_to_c_all r2
  WHERE r1.concept_code = r2.concept_code AND r2.snomed_code = r1.snomed_code AND r2.ctid < r1.ctid
) 
AND r1.precedence IS NULL; -- no automated modification for concepts with alternating mappings
-- Line 252-253: Delete 9999/9 (one entry)
--9. Preserve missing morphology mapped to generic neoplasm
DELETE FROM sources.r_to_c_all WHERE concept_code = '9999/9';
-- Line 255-268: 
--Code 9999/9 must NOT be encountered in final tables and should be removed during post-processing 
INSERT INTO sources.r_to_c_all
VALUES ('9999/9','Unknown histology','Maps to','108369006'); --Neoplasm
CREATE INDEX IF NOT EXISTS rtca_target_vc on sources.r_to_c_all (snomed_code);
ANALYZE sources.r_to_c_all;

-- Line 269-290: There are deprecated codes. CHECK!!
--check for deprecated concepts in r_to_c_all.snomed_code field
DO $_$
DECLARE
	codes text;
BEGIN
  SELECT
    string_agg (r.concept_code, ''',''')
  INTO codes
  FROM sources.r_to_c_all r
  LEFT JOIN omopcdm_jan24.concept c ON
  r.snomed_code::text = c.concept_code AND c.vocabulary_id = 'SNOMED' AND c.invalid_reason IS NULL
  WHERE c.concept_code IS NULL AND r.snomed_code != '-1';
--  IF codes IS NOT NULL THEN RAISE EXCEPTION 'Following attributes relations target deprecated SNOMED concepts: ''%''', codes ;
  IF codes IS NOT NULL THEN RAISE NOTICE 'Following attributes relations target deprecated SNOMED concepts: ''%''', codes ;
  END IF;
END $_$;

-- Line 291-306:
-- Create staging table
DROP TABLE IF EXISTS icdoscript.concept_stage CASCADE;
CREATE TABLE icdoscript.concept_stage(
  CONCEPT_ID INTEGER,
  CONCEPT_NAME VARCHAR(255) NOT NULL,
  DOMAIN_ID VARCHAR(20) NOT NULL,
  VOCABULARY_ID VARCHAR(20) NOT NULL,
  CONCEPT_CLASS_ID VARCHAR(20) NOT NULL,
  STANDARD_CONCEPT VARCHAR(1),
  CONCEPT_CODE VARCHAR(50) NOT NULL,
  VALID_START_DATE DATE NOT NULL,
  VALID_END_DATE DATE,
  INVALID_REASON VARCHAR(1)
);
TRUNCATE TABLE icdoscript.concept_stage;
--10. Populate_concept stage with attributes
--10.1. Topography
INSERT INTO icdoscript.concept_stage (
  CONCEPT_ID,
  CONCEPT_NAME,
  DOMAIN_ID,
  VOCABULARY_ID,
  CONCEPT_CLASS_ID,
  STANDARD_CONCEPT,
  CONCEPT_CODE,
  VALID_START_DATE,
  VALID_END_DATE
 )
SELECT 
  NULL,
  TRIM (concept_name),
  'Spec Anatomic Site',
  'ICDO3',
  'ICDO Topography',
  NULL,
  code,
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM sources.topo_source_iacr
WHERE code IS NOT NULL;
-- Line 291-306:
--10.2. Morphology
INSERT INTO icdoscript.concept_stage (
  CONCEPT_ID,
  CONCEPT_NAME,
  DOMAIN_ID,
  VOCABULARY_ID,
  CONCEPT_CLASS_ID,
  STANDARD_CONCEPT,
  CONCEPT_CODE,
  VALID_START_DATE,
  VALID_END_DATE
 )
SELECT 
  NULL,
  TRIM (term),
  'Observation',
  'ICDO3',
  'ICDO Histology',
  NULL,
  icdo32,
  COALESCE
  (
    c.valid_start_date,
    --new concept gets new date
    (
      SELECT latest_update
      FROM omopcdm_jan24.vocabulary
      WHERE latest_update IS NOT NULL
      LIMIT 1
--	  TO_DATE ('20231106', 'yyyymmdd')
    )
  ),
  TO_DATE ('20991231', 'yyyymmdd')
FROM sources.morph_source_who
LEFT JOIN omopcdm_jan24.concept c 
  ON icdo32 = c.concept_code AND c.vocabulary_id = 'ICDO3'
WHERE level NOT IN ('Related', 'Synonym') AND icdo32 IS NOT NULL;
-- Line 337-361:
--10.3. Get obsolete and unconfirmed morphology concepts
INSERT INTO icdoscript.concept_stage (
  CONCEPT_NAME,
  DOMAIN_ID,
  VOCABULARY_ID,
  CONCEPT_CLASS_ID,
  STANDARD_CONCEPT,
  CONCEPT_CODE,
  VALID_START_DATE,
  VALID_END_DATE,
  INVALID_REASON
 )
SELECT DISTINCT
  TRIM (m.concept_name),
  'Observation',
  'ICDO3',
  'ICDO Histology',
  NULL,
  m.concept_code,
  GREATEST (TO_DATE ('19700101', 'yyyymmdd'), c.valid_start_date), -- don't reduce existing start date
  (SELECT latest_update-1 FROM omopcdm_jan24.vocabulary WHERE vocabulary_id='ICDO3'),
--  TO_DATE('20220101', 'yyyymmdd'),
  'D'
FROM sources.r_to_c_all m
LEFT JOIN omopcdm_jan24.concept c 
  ON m.concept_code = c.concept_code AND c.vocabulary_id = 'ICDO3'
WHERE m.concept_code LIKE '%/%' AND m.concept_code NOT IN (SELECT concept_code FROM icdoscript.concept_stage WHERE concept_class_id = 'ICDO Histology');
-- Line 362-366: for VOCABULARY_PACK see https://github.com/OHDSI/Vocabulary-v5.0/tree/master/working/packages/vocabulary_pack
--10.4. Get dates from manual table
--DO $_$
--BEGIN
--	PERFORM VOCABULARY_PACK.ProcessManualConcepts();
--END $_$;
-- Instead run (modified from VOCABULARY_PACK.ProcessManualConcepts()):
-- First (modified from VOCABULARY_PACK.CheckManualConcepts()):
CREATE OR REPLACE FUNCTION CheckManualConcepts ()
RETURNS VOID AS
$BODY$
DECLARE
  z TEXT;
BEGIN
  SELECT s0.reason INTO z FROM (
  	SELECT
      CASE WHEN v.vocabulary_id IS NULL THEN 'vocabulary_id not found in the vocabulary: "'||cm.vocabulary_id||'"'
        WHEN cm.valid_end_date < cm.valid_start_date THEN 'valid_end_date < valid_start_date: '||TO_CHAR(cm.valid_end_date,'YYYYMMDD')||'+'||TO_CHAR(cm.valid_start_date,'YYYYMMDD')
        WHEN date_trunc('day', (cm.valid_start_date)) <> cm.valid_start_date THEN 'wrong format for valid_start_date (not truncated): '||TO_CHAR(cm.valid_start_date,'YYYYMMDD HH24:MI:SS')
        WHEN date_trunc('day', (cm.valid_end_date)) <> cm.valid_end_date THEN 'wrong format for valid_end_date (not truncated to YYYYMMDD): '||TO_CHAR(cm.valid_end_date,'YYYYMMDD HH24:MI:SS')
--	    WHEN (((cm.invalid_reason IS NULL AND cm.valid_end_date <> TO_DATE('20991231', 'yyyymmdd')) AND cm.vocabulary_id NOT IN (SELECT TRIM(v) FROM UNNEST(STRING_TO_ARRAY((SELECT var_value FROM devv5.config$ WHERE var_name='special_vocabularies'),',')) v))
-- What is devv5.config$???
        WHEN (((cm.invalid_reason IS NULL AND cm.valid_end_date <> TO_DATE('20991231', 'yyyymmdd')))
          OR (cm.invalid_reason IS NOT NULL AND cm.valid_end_date = TO_DATE('20991231', 'yyyymmdd'))) THEN 'wrong invalid_reason: "'||COALESCE(cm.invalid_reason,'NULL')||'" for '||TO_CHAR(cm.valid_end_date,'YYYYMMDD')
        WHEN d.domain_id IS NULL AND cm.domain_id IS NOT NULL THEN 'domain_id not found in the domain: "'||cm.domain_id||'"'
        WHEN cc.concept_class_id IS NULL AND cm.concept_class_id IS NOT NULL THEN 'concept_class_id not found in the concept_class: "'||cm.concept_class_id||'"'
        WHEN COALESCE(cm.standard_concept, 'S') NOT IN ('C','S','X') THEN 'wrong value for standard_concept: "'||cm.standard_concept||'"'
        WHEN COALESCE(cm.invalid_reason, 'D') NOT IN ('D','U','X') THEN 'wrong value for invalid_reason: "'||cm.invalid_reason||'"'
      END AS reason
    FROM sources.concept_manual cm
      LEFT JOIN omopcdm_jan24.vocabulary v ON v.vocabulary_id = cm.vocabulary_id
      LEFT JOIN omopcdm_jan24.domain d ON d.domain_id = cm.domain_id
      LEFT JOIN omopcdm_jan24.concept_class cc ON cc.concept_class_id = cm.concept_class_id
  ) AS s0
  WHERE s0.reason IS NOT NULL
  LIMIT 1;
  
  IF FOUND THEN
    RAISE EXCEPTION '%', z;
  END IF;
END;
$BODY$
LANGUAGE 'plpgsql';
-- Then:
DO $_$
BEGIN
  PERFORM CheckManualConcepts();
END $_$;
-- Then:
UPDATE icdoscript.concept_stage cs
SET concept_name = COALESCE(cm.concept_name, cs.concept_name),
  domain_id = COALESCE(cm.domain_id, cs.domain_id),
  concept_class_id = COALESCE(cm.concept_class_id, cs.concept_class_id),
  standard_concept = CASE 
    WHEN cm.standard_concept = 'X' --don't change the original standard_concept if standard_concept in the cm is 'X'
      THEN cs.standard_concept
    ELSE cm.standard_concept
    END,
  valid_start_date = COALESCE(cm.valid_start_date, cs.valid_start_date),
  valid_end_date = COALESCE(cm.valid_end_date, cs.valid_end_date),
  invalid_reason = CASE 
    WHEN cm.invalid_reason = 'X' --don't change the original invalid_reason if invalid_reason in the cm is 'X'
      THEN cs.invalid_reason
    ELSE cm.invalid_reason
    END
FROM sources.concept_manual cm
JOIN omopcdm_jan24.vocabulary v ON v.vocabulary_id = cm.vocabulary_id
-- No latest_update in vocabulary
WHERE v.latest_update IS NOT NULL
  AND cm.concept_code = cs.concept_code
--WHERE cm.concept_code = cs.concept_code
  AND cm.vocabulary_id = cs.vocabulary_id; 
--add new records
INSERT INTO icdoscript.concept_stage (
  concept_name,
  domain_id,
  vocabulary_id,
  concept_class_id,
  standard_concept,
  concept_code,
  valid_start_date,
  valid_end_date,
  invalid_reason
)
SELECT cm.*
FROM sources.concept_manual cm
JOIN omopcdm_jan24.vocabulary v ON v.vocabulary_id = cm.vocabulary_id
-- No latest_update in vocabulary
WHERE v.latest_update IS NOT NULL AND NOT EXISTS (SELECT 1 FROM icdoscript.concept_stage cs_int WHERE cs_int.concept_code = cm.concept_code AND cs_int.vocabulary_id = cm.vocabulary_id);
--WHERE NOT EXISTS (SELECT 1 FROM icdoscript.concept_stage cs_int WHERE cs_int.concept_code = cm.concept_code AND cs_int.vocabulary_id = cm.vocabulary_id);
-- Nothing happened here!!!
-- Line 367-369:
--11. Form table with replacements to handle historic changes for combinations and histologies
DROP TABLE IF EXISTS icdoscript.code_replace;
-- Line 371-388:
-- First load changelog_extract
DROP TABLE IF EXISTS sources.changelog_extract CASCADE;
CREATE TABLE sources.changelog_extract(
  code VARCHAR(20) NOT NULL,
  terms VARCHAR(255) NOT NULL,
  fate VARCHAR(20) NOT NULL
);
TRUNCATE TABLE sources.changelog_extract;
COPY sources.changelog_extract FROM 'C:/Archives/ohdsi/ICD-O-3/ICDO3 vocab/changelog_extract.csv' CSV
DELIMITER ',' HEADER QUOTE ''''
ENCODING 'UTF8';
--11.1. Explicitly stated histologies replacements
CREATE TABLE icdoscript.code_replace AS
SELECT DISTINCT
  code AS old_code,
  SUBSTRING (fate, '\d{4}\/\d$') AS code,
  'ICDO Histology' AS concept_class_id
FROM sources.changelog_extract
WHERE fate ~ 'Moved to \d{4}\/\d'
  UNION ALL
SELECT DISTINCT
  code AS old_code,
  LEFT (code,4) || '/' || RIGHT (fate,1) AS code,
  'ICDO Histology' AS concept_class_id
FROM sources.changelog_extract
WHERE fate ~ 'Moved to \/\d';
-- Line 389-405:
--11.2. Same names; old code deprecated
INSERT INTO icdoscript.code_replace
SELECT DISTINCT
  d2.concept_code AS old_code,
  d1.concept_code AS code,
  'ICDO Histology' AS concept_class_id
FROM icdoscript.concept_stage d1
JOIN icdoscript.concept_stage d2 
  ON d1.invalid_reason IS NULL AND d2.invalid_reason IS NOT NULL AND d1.concept_name = d2.concept_name AND d1.concept_class_id = 'ICDO Histology' AND d2.concept_class_id = 'ICDO Histology'
LEFT JOIN icdoscript.code_replace 
  ON old_code = d2.concept_code
WHERE old_code IS NULL;
-- Line 406-436:
--11.3. Form table with existing and old combinations
DROP TABLE IF EXISTS icdoscript.comb_table;
--Existing
CREATE TABLE icdoscript.comb_table AS
SELECT DISTINCT
  *,
  histology_behavior || '-' || site AS concept_code
FROM sources.icdo3_valid_combination c;
--Old; will be deprecated; transfer combinations to new concepts
INSERT INTO icdoscript.comb_table
SELECT
  r.code,
  c.site,
  r.code || '-' || c.site AS concept_code
FROM icdoscript.comb_table c
JOIN icdoscript.code_replace r 
  ON r.old_code = c.histology_behavior
WHERE (r.code,c.site,r.code || '-' || c.site) NOT IN (SELECT * FROM icdoscript.comb_table);
INSERT INTO icdoscript.code_replace
SELECT
  c.concept_code AS old_code,
  r.code || '-' || c.site AS code,
  'ICDO Condition'
FROM icdoscript.comb_table c
JOIN icdoscript.code_replace r 
  ON r.old_code = c.histology_behavior;
-- Line 437-458:
--11.4. Create mappings for missing topography/morphology
INSERT INTO icdoscript.comb_table
SELECT
	'9999/9', -- unspecified morphology, mapped to generic neoplasm
	concept_code,
	'NULL-' || concept_code
FROM icdoscript.concept_stage
WHERE concept_class_id = 'ICDO Topography' AND concept_code LIKE '%.%' -- not hierarchical
  UNION ALL
SELECT
	concept_code,
	'-1',--unspecified topography, combination will get mapped to a concept without a topography
	concept_code || '-NULL'
FROM icdoscript.concept_stage
WHERE concept_class_id = 'ICDO Histology' AND concept_code LIKE '%/%'; -- not hierarchical
-- Line 459-486:
-- 12. Populate concept_stage with combinations
INSERT INTO icdoscript.concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
SELECT DISTINCT
    REPLACE (m.concept_name, ', NOS', ', NOS,') || ' of ' || LOWER (LEFT (t.concept_name, 1)) || RIGHT (t.concept_name, -1) AS concept_name,
  'Condition',
  'ICDO3',
  'ICDO Condition',
  NULL,
  c.concept_code,
  --get validdity period from histology concept
  m.valid_start_date,
  m.valid_end_date,
  CASE 
    WHEN r.code IS NOT NULL THEN 'D'
    ELSE NULL
  END
FROM icdoscript.comb_table c
JOIN icdoscript.concept_stage m 
  ON c.histology_behavior = m.concept_code
JOIN icdoscript.concept_stage t 
 ON	c.site = t.concept_code
LEFT JOIN icdoscript.code_replace r 
  ON r.old_code = c.concept_code
WHERE c.concept_code !~ '(9999\/9|NULL)';
-- Line 487-510:
--12.1. One-legged concepts (no topography)
INSERT INTO icdoscript.concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
SELECT DISTINCT
  'Neoplasm defined only by histology: '||c.concept_name,
  'Condition',
  'ICDO3',
  'ICDO Condition',
  NULL,
  c.concept_code || '-NULL',
--get validity period from histology concept
  c.valid_start_date,
  c.valid_end_date,
  CASE
    WHEN r.code IS NOT NULL THEN 'D'
    ELSE NULL
  END
FROM icdoscript.concept_stage c
LEFT JOIN icdoscript.code_replace r 
  ON r.old_code = c.concept_code || '-NULL'
WHERE c.concept_class_id = 'ICDO Histology' AND c.concept_code like '%/%'; -- not hierarchical
-- Line 511-528:
--12.2. One-legged concepts (no histology)
INSERT INTO icdoscript.concept_stage (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
SELECT
  NULL,
  'Neoplasm defined only by topography: '||concept_name,
  'Condition',
  'ICDO3',
  'ICDO Condition',
  NULL,
  'NULL-' || concept_code,
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd'),
  NULL 
FROM icdoscript.concept_stage
WHERE concept_class_id = 'ICDO Topography' AND concept_code LIKE '%.%'; -- not hierarchical
-- Line 529-700:
--13. Form stable list of existing precoordinated concepts in SNOMED
DROP TABLE IF EXISTS icdoscript.snomed_target_prepared;
-- Step 1:
DROP TABLE IF EXISTS icdoscript.def_status;
CREATE TABLE icdoscript.def_status AS --form list of defined neoplasia concepts without extraneous relations
(
  SELECT DISTINCT 
    c.concept_code,
    FIRST_VALUE (f.statusid) OVER (PARTITION BY f.id ORDER BY f.effectivetime DESC) AS statusid
  FROM snomed.sct2_concept_full_merged f
  JOIN omopcdm_jan24.concept c 
    ON c.vocabulary_id = 'SNOMED' AND c.standard_concept = 'S' AND c.concept_code = f.id :: varchar
  -- filter out new sources, as SNOMED update could have been delayed
-- PICK DATE
  WHERE TO_DATE(f.effectivetime :: varchar, 'yyyymmdd') <= (SELECT TO_DATE(SUBSTRING(vocabulary_version FROM 78 FOR 10),'yyyy-mm-dd') FROM omopcdm_jan24.vocabulary WHERE vocabulary_id = 'SNOMED')
--  WHERE TO_DATE(f.effectivetime :: varchar, 'yyyymmdd') <= TO_DATE('20200620', 'yyyymmdd')
);
-- Step 2:
DROP TABLE IF EXISTS icdoscript.snomed_concept;
CREATE TABLE icdoscript.snomed_concept AS
(
  SELECT
    c.concept_id,
    c.concept_code,
    c.concept_name
  FROM omopcdm_jan24.concept c
  JOIN icdoscript.snomed_ancestor a 
    ON a.ancestor_concept_code IN
    (
      '399981008',--Neoplasm and/or hamartoma
      '414026006'	--Disorder of hematopoietic cell proliferation
    ) 
    AND a.descendant_concept_code::text = c.concept_code 
    AND c.vocabulary_id = 'SNOMED'
  JOIN icdoscript.def_status d 
    ON d.statusid = 900000000000073002  -- Fully defined
    AND d.concept_code = c.concept_code
  LEFT JOIN omopcdm_jan24.concept_relationship r  --concepts defined outside of ICDO3 model
    ON r.concept_id_1 = c.concept_id 
    AND r.relationship_id IN
    (
      'Followed by',
      'Using finding inform',
      'Finding asso with',
      'Has interprets',
      'Has clinical course',
      'Using finding method',
      'Has causative agent',
      'Has interpretation',
      'Occurs after',
      'Has due to'
    )
  LEFT JOIN omopcdm_jan24.concept_relationship r1  --refers to morphologies that are not neoplasms
    ON r1.relationship_id = 'Has asso morph' 
    AND r1.concept_id_1 = c.concept_id 
    AND NOT EXISTS
    (
      SELECT
      FROM icdoscript.snomed_ancestor AS sa
      JOIN omopcdm_jan24.concept AS a 
        ON a.concept_id = r1.concept_id_2
      WHERE sa.ancestor_concept_code IN 
        (
          '400177003',	--Neoplasm
          '415181008',	--Proliferation of hematopoietic cell type
          '25723000',	--Dysplasia
          '76197007'	--Hyperplasia
        ) 
      AND sa.descendant_concept_code::text = a.concept_code
    )
  LEFT JOIN omopcdm_jan24.concept_relationship r2 --has occurence that has outlying targets
    ON r1.relationship_id = 'Has occurrence'
    AND r2.concept_id_1 = c.concept_id
    AND r2.concept_id_2 IN
    (
      4121979, --Fetal period
      4275212, --Infancy
      4116829, --Childhood
      4116830, --Congenital
      35624340 --Period of life between birth and death
    )
  WHERE r.relationship_id IS NULL
    AND r1.relationship_id IS NULL
    AND r2.relationship_id IS NULL
    AND NOT EXISTS --Branches that should not be considered 'defined'
    (
      SELECT
      FROM icdoscript.snomed_ancestor x
      WHERE x.descendant_concept_code::text = c.concept_code
	  AND x.ancestor_concept_code IN
        (
          '111941005',	--Familial disease
          '255051004',	--Tumor of unknown origin
          '127332000',	--Fetal neoplasm
          '115966001',	--Occupational disorder
          '10749871000119100',	--Malignant neoplastic disease in pregnancy
          '765205004',	--Disorder in remission
          '127274007', --Neoplasm of lymph nodes of multiple sites
          '448563005',	--Functionless pituitary neoplasm
          --BROKEN IN CURRENT SNOMED: CHECK THIS NEXT RELEASE!
          '96901000119105', --Prostate cancer metastatic to eye (disorder)
          '255068000'	--Carcinoma of bone, connective tissue, skin and breast
        )
    )
);
-- Step 3: Takes a long time to run (~3 hours on laptop)!!! Maybe split it up to make it faster?
--CREATE TABLE icdoscript.snomed_target_prepared AS
--SELECT DISTINCT
--  c.concept_code,
--  c.concept_name,
--  COALESCE (x1.concept_code, '-1') AS t_id, --preserve absent topography as meaning
--  x2.concept_code AS m_id
--FROM icdoscript.snomed_concept c
--LEFT JOIN omopcdm_jan24.concept_relationship r1 
--  ON r1.concept_id_1 = c.concept_id AND r1.relationship_id = 'Has finding site'
--LEFT JOIN omopcdm_jan24.concept x1 
--  ON x1.concept_id = r1.concept_id_2 AND x1.vocabulary_id = 'SNOMED' AND
--  NOT EXISTS --topography may be duplicated (ancestor/descendant)
--  (
--    SELECT
--    FROM omopcdm_jan24.concept_relationship x
--    JOIN omopcdm_jan24.concept n 
--	  ON n.concept_id = x.concept_id_2
--    JOIN icdoscript.snomed_ancestor a 
--	  ON a.descendant_concept_code::text = n.concept_code AND a.ancestor_concept_code::text = x1.concept_code AND x.concept_id_1 = r1.concept_id_1 
--	  AND  x.relationship_id = 'Has finding site' AND a.ancestor_concept_code != a.descendant_concept_code
--  )
--JOIN omopcdm_jan24.concept_relationship r2 
--  ON r2.concept_id_1 = c.concept_id AND r2.relationship_id = 'Has asso morph'
--JOIN omopcdm_jan24.concept x2 
--  ON x2.concept_id = r2.concept_id_2 AND  x2.vocabulary_id = 'SNOMED' 
--  AND NOT EXISTS --morphology may be duplicated (ancestor/descendant)
--  (
--    SELECT
--    FROM omopcdm_jan24.concept_relationship x
--    JOIN omopcdm_jan24.concept n 
--      ON n.concept_id = x.concept_id_2
--    JOIN icdoscript.snomed_ancestor a 
--      ON a.descendant_concept_code::text = n.concept_code AND a.ancestor_concept_code::text = x2.concept_code AND x.concept_id_1 = r2.concept_id_1 
--      AND x.relationship_id = 'Has asso morph' AND a.ancestor_concept_code != a.descendant_concept_code
--  );
CREATE TABLE icdoscript.tmp1 AS  
SELECT 
    a.ancestor_concept_code::text AS ancestor_concept_code,
	x.concept_id_1 AS concept_id_1
    FROM omopcdm_jan24.concept_relationship x
    JOIN omopcdm_jan24.concept n 
	  ON n.concept_id = x.concept_id_2
    JOIN icdoscript.snomed_ancestor a 
	  ON a.descendant_concept_code::text = n.concept_code AND x.relationship_id = 'Has finding site' AND a.ancestor_concept_code != a.descendant_concept_code; 
CREATE TABLE icdoscript.tmp2 AS  
SELECT 
    a.ancestor_concept_code::text AS ancestor_concept_code,
	x.concept_id_1 AS concept_id_1
    FROM omopcdm_jan24.concept_relationship x
    JOIN omopcdm_jan24.concept n 
	  ON n.concept_id = x.concept_id_2
    JOIN icdoscript.snomed_ancestor a 
	  ON a.descendant_concept_code::text = n.concept_code AND x.relationship_id = 'Has asso morph' AND a.ancestor_concept_code != a.descendant_concept_code;
CREATE TABLE icdoscript.snomed_target_prepared AS
SELECT DISTINCT
  c.concept_code,
  c.concept_name,
  COALESCE (x1.concept_code, '-1') AS t_id, --preserve absent topography as meaning
  x2.concept_code AS m_id
FROM icdoscript.snomed_concept c
LEFT JOIN omopcdm_jan24.concept_relationship r1 
  ON r1.concept_id_1 = c.concept_id AND r1.relationship_id = 'Has finding site'
LEFT JOIN omopcdm_jan24.concept x1 
  ON x1.concept_id = r1.concept_id_2 AND x1.vocabulary_id = 'SNOMED' AND
  NOT EXISTS --topography may be duplicated (ancestor/descendant)
  (
    SELECT
    FROM icdoscript.tmp1 t1
	WHERE t1.ancestor_concept_code = x1.concept_code AND t1.concept_id_1 = r1.concept_id_1 
  )
JOIN omopcdm_jan24.concept_relationship r2 
  ON r2.concept_id_1 = c.concept_id AND r2.relationship_id = 'Has asso morph'
JOIN omopcdm_jan24.concept x2 
  ON x2.concept_id = r2.concept_id_2 AND  x2.vocabulary_id = 'SNOMED' 
  AND NOT EXISTS --morphology may be duplicated (ancestor/descendant)
  (
	SELECT
    FROM icdoscript.tmp2 t2
	WHERE t2.ancestor_concept_code = x2.concept_code AND t2.concept_id_1 = r2.concept_id_1 
  );
DROP TABLE icdoscript.tmp1;
DROP TABLE icdoscript.tmp2;
CREATE INDEX idx_snomed_target_prepared ON icdoscript.snomed_target_prepared (concept_code);
CREATE INDEX idx_snomed_target_attr ON icdoscript.snomed_target_prepared (m_id, t_id);
CREATE INDEX idx_snomed_target_t ON icdoscript.snomed_target_prepared (t_id);
ANALYZE icdoscript.snomed_target_prepared;
DELETE FROM icdoscript.snomed_target_prepared a
WHERE a.t_id = '-1' 
  AND EXISTS
  (
    SELECT
    FROM icdoscript.snomed_target_prepared b
    WHERE a.concept_code = b.concept_code AND b.t_id != '-1'
  );
ANALYZE icdoscript.snomed_target_prepared;
-- Line 701-745:
--14. Form mass of all possible matches to filter later
DROP TABLE IF EXISTS icdoscript.match_blob;
CREATE TABLE icdoscript.match_blob AS
SELECT DISTINCT
  o.concept_code AS i_code,
  s.concept_code AS s_id,
  s.m_id,
  s.t_id,
  CASE 
    WHEN (ta.descendant_concept_code = ta.ancestor_concept_code) AND (t.relationship_id = 'Maps to') THEN TRUE
    ELSE FALSE
  END AS t_exact,
  CASE 
    WHEN (ma.descendant_concept_code = ma.ancestor_concept_code) AND (m.relationship_id = 'Maps to') THEN TRUE
    ELSE FALSE
  END AS m_exact,
  1 AS debug_id
FROM icdoscript.comb_table o
--topography & up
JOIN sources.r_to_c_all t 
  ON t.concept_code = o.site
JOIN icdoscript.snomed_ancestor ta 
  ON ta.descendant_concept_code = t.snomed_code
--morphology & up
JOIN sources.r_to_c_all m 
  ON m.concept_code = o.histology_behavior
JOIN icdoscript.snomed_ancestor ma 
  ON ma.descendant_concept_code = m.snomed_code
JOIN icdoscript.snomed_target_prepared s 
  ON s.t_id = ta.ancestor_concept_code::text AND s.m_id = ma.ancestor_concept_code::text
WHERE o.concept_code NOT IN (SELECT old_code FROM icdoscript.code_replace);
-- Line 746-785:
--14.1 match to concepts without topographies
INSERT INTO icdoscript.match_blob
SELECT DISTINCT
  o.concept_code AS i_code,
  s.concept_code AS s_id,
  s.m_id,
  '-1' AS t_id,
-- concepts with known or 'deliberately' unknown topography should not have t_exact = TRUE
  COALESCE ((t.relationship_id = 'Maps to' AND t.snomed_code = '-1'),TRUE) AS t_exact, 
  (ma.descendant_concept_code = ma.ancestor_concept_code) AND (m.relationship_id = 'Maps to') AS m_exact,
  2 AS debug_id
FROM icdoscript.comb_table o
--morphology & up
JOIN sources.r_to_c_all m 
  ON m.concept_code = o.histology_behavior
JOIN icdoscript.snomed_ancestor ma 
  ON  ma.descendant_concept_code = m.snomed_code
--check if topography is Exactly unknown or just missing
LEFT JOIN sources.r_to_c_all t 
  ON t.concept_code = o.site
JOIN icdoscript.snomed_target_prepared s 
  ON s.t_id IN ('-1','87784001') AND s.m_id = ma.ancestor_concept_code::text --"Soft tissues" is not a real topography
WHERE o.concept_code NOT IN (SELECT old_code FROM icdoscript.code_replace);
CREATE INDEX idx_blob ON icdoscript.match_blob (i_code, s_id);
CREATE INDEX idx_blob_s ON icdoscript.match_blob (s_id);
ANALYZE icdoscript.match_blob;
-- Line 786-838:
--14.2 match blood cancers to concepts without topographes
--Lymphoma/Leukemia group concepts relating to generic hematopoietic structures as topography
INSERT INTO icdoscript.match_blob
SELECT DISTINCT
  cs.concept_code AS i_code,
  s.concept_code AS s_id,
  s.m_id,
  '-1',
  TRUE AS t_exact,
  (ma.descendant_concept_code = ma.ancestor_concept_code) AND (m.relationship_id = 'Maps to') AS m_exact,
  3 AS debug_id
FROM icdoscript.comb_table o
JOIN icdoscript.concept_stage cs
  ON o.concept_code = cs.concept_code
--morphology & up
JOIN sources.r_to_c_all m
  ON m.concept_code = o.histology_behavior
JOIN icdoscript.snomed_ancestor ma
  ON ma.descendant_concept_code = m.snomed_code
JOIN icdoscript.snomed_target_prepared s
  ON s.m_id = ma.ancestor_concept_code::text
WHERE LEFT (o.histology_behavior,3) BETWEEN '9590' AND '9990'  -- all hematological neoplasms
  AND o.site ~ '^C42\.[034]$' -- Blood, Reticuloendothelial system, Hematopoietic NOS
  AND s.t_id IN
  (
    '14016003',	--Bone marrow structure
    '254198003',--Lymph nodes of multiple sites
    '57171008',	--Hematopoietic system structure
    '87784001',	--Soft tissues
    '127908000',--Mononuclear phagocyte system structure
    '-1' 		-- Unknown
  )
  AND NOT EXISTS
  (
    SELECT 1
    FROM icdoscript.match_blob m
    WHERE m.i_code = cs.concept_code AND m.m_exact AND	m.t_exact
  );
ANALYZE icdoscript.match_blob;
-- Line 839-860:
--14.2. Delete concepts that mention topographies contradicting source condition
DELETE FROM icdoscript.match_blob m
WHERE NOT m.t_exact -- for lymphomas/leukemias
  AND EXISTS
  (
    SELECT 1
    FROM icdoscript.snomed_target_prepared r
    WHERE r.concept_code = m.s_id
      AND NOT EXISTS 
      (
        SELECT 1
        FROM icdoscript.comb_table c
        JOIN sources.r_to_c_all t 
		  ON t.concept_code = c.site
        JOIN icdoscript.snomed_ancestor a 
		  ON a.descendant_concept_code = t.snomed_code
        WHERE a.ancestor_concept_code::text = r.t_id AND c.concept_code = m.i_code
      )
      AND r.t_id != '-1'
  );
 -- Line 861-879:
 --14.3. Delete concepts that mention morphologies contradicting source condition
DELETE FROM icdoscript.match_blob m
WHERE EXISTS
  (
    SELECT 1
    FROM icdoscript.snomed_target_prepared r
    WHERE r.concept_code = m.s_id
      AND NOT EXISTS 
      (
        SELECT 1
        FROM icdoscript.comb_table c
        JOIN sources.r_to_c_all t 
		  ON t.concept_code = c.histology_behavior
        JOIN icdoscript.snomed_ancestor a 
		  ON a.descendant_concept_code = t.snomed_code
        WHERE a.ancestor_concept_code::text = r.m_id AND c.concept_code = m.i_code
      )
  );
 -- Line 880-904: 
 --14.4. Handle overlapping lesion
DELETE FROM icdoscript.match_blob
WHERE s_id IN
  (
    SELECT descendant_concept_code::text
    FROM icdoscript.snomed_ancestor 
    WHERE ancestor_concept_code IN
      (
        109821008, --Overlapping malignant neoplasm of gastrointestinal tract
        188256008, --Malignant neoplasm of overlapping lesion of urinary organs
        109384006, --Overlapping malignant neoplasm of heart, mediastinum and pleura
        109347009, --Overlapping malignant neoplasm of bone and articular cartilage
        109851002, --Overlapping malignant neoplasm of retroperitoneum and peritoneum
        254388002, --Overlapping neoplasm of oral cavity and lips and salivary glands
        109919002, --Overlapping malignant neoplasm of peripheral nerves and autonomic nervous system
        109948008, --Overlapping malignant neoplasm of eye and adnexa, primary
        188256008 --Malignant neoplasm of overlapping lesion of urinary organs 
      )
      
  ) 
  AND i_code NOT LIKE '%.8'; --code for overlapping lesions
ANALYZE icdoscript.match_blob;
 -- Line 905-919: Takes long -> rewrite
 --14.5. malignant WBC disorder special
-- DELETE FROM icdoscript.match_blob
-- WHERE s_id = '277543005' --Malignant white blood cell disorder
--   AND i_code not in
--   (
--     SELECT c.concept_code
--     FROM icdoscript.comb_table c
--     JOIN sources.r_to_c_all t 
-- 	  ON t.concept_code = c.histology_behavior
--     JOIN icdoscript.snomed_ancestor ca 
-- 	  ON ca.ancestor_concept_code = '414388001' AND ca.descendant_concept_code = t.snomed_code --Hematopoietic neoplasm   
--   );
CREATE TABLE icdoscript.tmp1 AS
(
SELECT c.concept_code
    FROM icdoscript.comb_table c
    JOIN sources.r_to_c_all t 
	  ON t.concept_code = c.histology_behavior
    JOIN icdoscript.snomed_ancestor ca 
	  ON ca.ancestor_concept_code = '414388001' AND ca.descendant_concept_code = t.snomed_code --Hematopoietic neoplasm  
);
DELETE FROM icdoscript.match_blob
WHERE s_id = '277543005' --Malignant white blood cell disorder
  AND i_code not in
  ( 
    SELECT concept_code
	FROM icdoscript.tmp1 
  );
DROP TABLE icdoscript.tmp1;
-- Line 920-937:
--15. Core logic
--15.1. For t_exact and m_exact, remove descendants where ancestors are available as targets
--DELETE FROM icdoscript.match_blob m
--WHERE EXISTS
--	(
--		SELECT 1
--		FROM icdoscript.snomed_ancestor a
--		JOIN icdoscript.match_blob b ON
--			b.s_id != m.s_id AND
--			m.s_id = a.descendant_concept_code AND
--			b.s_id = a.ancestor_concept_code AND
--			b.i_code = m.i_code	AND
--			b.t_exact AND
--			b.m_exact
--	) AND
--	m.t_exact AND
--	m.m_exact
--;
CREATE TABLE icdoscript.tmp1 AS
(
SELECT 
    b.s_id AS s_id,
	a.descendant_concept_code::text AS descendant_concept_code,
	b.i_code AS i_code
    FROM icdoscript.snomed_ancestor a
    JOIN icdoscript.match_blob b 
	  ON b.s_id = a.ancestor_concept_code::text AND b.t_exact AND b.m_exact
);
DELETE FROM icdoscript.match_blob m
WHERE EXISTS
  (
    SELECT 1
    FROM icdoscript.tmp1 t1
	WHERE t1.s_id != m.s_id AND m.s_id = t1.descendant_concept_code AND t1.i_code = m.i_code
  ) 
  AND m.t_exact 
  AND m.m_exact;
DROP TABLE icdoscript.tmp1; 
-- Line 938-958: Takes a long time to run (not finished after >12 hours on laptop so we split it up)!!!
--15.2. Do the same just for for t_exact with morphology being less precise than best alternative
-- solves problematic concepts like 255168002 Benign neoplasm of esophagus, stomach and/or duodenum (disorder)
--Multiple topographies
--DELETE FROM icdoscript.match_blob m
--WHERE EXISTS
--  (
--    SELECT 1
--    FROM icdoscript.snomed_ancestor a
--    JOIN icdoscript.match_blob b 
--	  ON b.s_id != m.s_id AND m.s_id = a.descendant_concept_code::text AND b.s_id = a.ancestor_concept_code::text AND b.i_code = m.i_code  AND b.t_exact
--    --don't remove if morphology is less precise
--    JOIN icdoscript.snomed_ancestor x 
--	  ON x.descendant_concept_code::text = b.m_id AND x.ancestor_concept_code::text = m.m_id
--  ) 
--  AND m.t_exact;
-- Step 1: takes 3 minutes
CREATE TABLE icdoscript.tmp1 AS
(
  SELECT 
  a.descendant_concept_code::text AS descendant_concept_code,
  b.s_id AS s_id,
  b.m_id AS m_id,
  b.i_code AS i_code
  FROM icdoscript.snomed_ancestor a
  JOIN icdoscript.match_blob b 
    ON b.s_id = a.ancestor_concept_code::text AND b.t_exact
  WHERE EXISTS
    (
      SELECT 1
      FROM icdoscript.match_blob m
      WHERE b.s_id != m.s_id AND m.s_id = a.descendant_concept_code::text AND b.i_code = m.i_code
    )
);
-- Step 2: 
CREATE TABLE icdoscript.tmp2 AS
  (
    SELECT 
	  t1.descendant_concept_code::text AS descendant_concept_code,
	  x.ancestor_concept_code::text AS ancestor_concept_code,
      t1.s_id AS s_id,
      t1.m_id AS m_id,
      t1.i_code AS i_code
    FROM icdoscript.tmp1 t1
    --don't remove if morphology is less precise
    JOIN icdoscript.snomed_ancestor x 
      ON x.descendant_concept_code::text = t1.m_id 
);
-- Step 3: 
DELETE FROM icdoscript.match_blob m
WHERE EXISTS
  (
    SELECT 1
    FROM icdoscript.tmp2 t2
    WHERE t2.s_id != m.s_id AND m.s_id = t2.descendant_concept_code AND t2.i_code = m.i_code AND t2.ancestor_concept_code::text = m.m_id
  ) 
  AND m.t_exact
;
DROP TABLE icdoscript.tmp1;
DROP TABLE icdoscript.tmp2;
-- Line 959-967: This also takes too long (>40 minutes on laptop) so we split it up.
 --15.3. Remove ancestors where descendants are available as targets
--DELETE FROM icdoscript.match_blob m
--WHERE EXISTS
--  (
--    SELECT 1
--    FROM icdoscript.snomed_ancestor a
--    JOIN icdoscript.match_blob b 
--	  ON b.s_id != m.s_id AND b.s_id = a.descendant_concept_code::text AND m.s_id = a.ancestor_concept_code::text AND b.i_code = m.i_code
--  );
-- Step 1:
CREATE TABLE icdoscript.tmp1 AS
(
  SELECT 
  b.s_id AS s_id,
  a.ancestor_concept_code::text AS ancestor_concept_code,
  b.i_code AS i_code
  FROM icdoscript.snomed_ancestor a
  JOIN icdoscript.match_blob b 
  ON b.s_id = a.descendant_concept_code::text 
);
-- Step 2a:
DELETE FROM icdoscript.tmp1 t
WHERE NOT EXISTS
  (
    SELECT 1
    FROM icdoscript.match_blob m
    WHERE t.ancestor_concept_code = m.s_id
  );
-- Step 2b:
DELETE FROM icdoscript.tmp1 t
WHERE NOT EXISTS
  (
    SELECT 1
    FROM icdoscript.match_blob m
    WHERE t.i_code = m.i_code
  );
-- Step 3: This just takes 1 minute or so.
DELETE FROM icdoscript.match_blob m
WHERE EXISTS
  (
    SELECT 1
    FROM icdoscript.tmp1 t
    WHERE t.s_id != m.s_id AND m.s_id = t.ancestor_concept_code AND t.i_code = m.i_code
  );
-- Step 4:
DROP TABLE icdoscript.tmp1;
--debug artifact
TRUNCATE TABLE icdoscript.concept_relationship_stage;
-- Line 977-1004:
--16. Fill mappings and other relations to SNOMED in concept_relationship_stage
--16.1. Write 'Maps to' relations where perfect one-to-one mappings are available and unique
-- Step 1:
DROP TABLE IF EXISTS icdoscript.monorelation;
CREATE TABLE icdoscript.monorelation AS
(
  SELECT i_code
  FROM icdoscript.match_blob
  WHERE t_exact AND m_exact
  GROUP BY i_code
  HAVING COUNT (DISTINCT s_id) = 1
);
-- Step 2:
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  m.i_code,
  m.s_id AS concept_code,
  'ICDO3',
  'SNOMED',
  'Maps to',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.match_blob m
JOIN icdoscript.monorelation o 
USING (i_code)
WHERE i_code not like '%/6%' AND m.t_exact AND m.m_exact; -- exclude secondary cancer as they now are mapped to cancer modifier
-- Line 1005-1107:
--Interim Table with Mappings
DROP TABLE IF EXISTS icdoscript.icdo3_to_cm_metastasis;
--ICDO3 /6 codes mappings to Cancer Modifier
-- Step 1:
DROP TABLE IF EXISTS icdoscript.getherd_mts_codes;
CREATE TABLE icdoscript.getherd_mts_codes AS
(
   --aggregate the source
  SELECT DISTINCT
    concept_name,
    concept_code,
    split_part(concept_code,'-',2) as tumor_site_code,
    vocabulary_id
  FROM icdoscript.concept_stage c
  WHERE c.vocabulary_id = 'ICDO3' AND c.concept_class_id = 'ICDO Condition' AND c.concept_code ILIKE '%/6%'
);
-- Step 2:
DROP TABLE IF EXISTS icdoscript.tabb;
CREATE TABLE icdoscript.tabb AS
(
  SELECT DISTINCT
    tumor_site_code,
    s.vocabulary_id,
    cc.concept_id AS snomed_id,
    cc.concept_name AS snomed_name,
    cc.vocabulary_id AS snomed_voc,
    cc.concept_code AS snomed_code
  FROM icdoscript.getherd_mts_codes s
  LEFT JOIN omopcdm_jan24.concept c
    ON s.tumor_site_code = c.concept_code AND c.concept_class_id = 'ICDO Topography'
  LEFT JOIN omopcdm_jan24.concept_relationship cr
    ON c.concept_id = cr.concept_id_1 AND cr.invalid_reason IS NULL AND cr.relationship_id = 'Maps to'
  LEFT JOIN omopcdm_jan24.concept cc
    ON cr.concept_id_2 = cc.concept_id AND cr.invalid_reason IS NULL AND cc.standard_concept = 'S'
);
-- Step 3:
DROP TABLE IF EXISTS icdoscript.tabbc;
CREATE TABLE icdoscript.tabbc AS
(
  SELECT 
    tumor_site_code,
    t.vocabulary_id AS icd_voc,
    snomed_id,
    snomed_name,
    snomed_voc,
    snomed_code,
    concept_id,
    concept_name,
    domain_id,
    c.vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    c.valid_start_date,
    c.valid_end_date,
    c.invalid_reason
  FROM icdoscript.tabb t -- table with SITEtoSNOMED mappngs
  JOIN omopcdm_jan24.concept_relationship cr
    ON t.snomed_id=cr.concept_id_1
  JOIN omopcdm_jan24.concept c
    ON c.concept_id=cr.concept_id_2 AND c.concept_class_id='Metastasis'
);
-- Step 4: devv5.similarity seems to be similarity from pg_trgm
DROP EXTENSION IF EXISTS pg_trgm;
CREATE EXTENSION pg_trgm; -- then devv5.similarity -> similarity
DROP TABLE IF EXISTS icdoscript.similarity_tab;
CREATE TABLE icdoscript.similarity_tab AS
(
  SELECT DISTINCT
    CASE 
	  WHEN tumor_site_code = 'C38.4' THEN ROW_NUMBER() OVER (PARTITION BY tumor_site_code ORDER BY similarity(snomed_name,concept_name) ASC)
      ELSE ROW_NUMBER() OVER (PARTITION BY tumor_site_code ORDER BY similarity(snomed_name,concept_name) DESC)
	END AS similarity,
    tumor_site_code,
    icd_voc,
    snomed_id,
    snomed_name,
    snomed_voc,
    snomed_code,
    concept_id,
    concept_name,
    domain_id,
    tabbc.vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    valid_start_date,
    valid_end_date,
    invalid_reason
  FROM icdoscript.tabbc
);
-- Step 5:
CREATE TABLE icdoscript.icdo3_to_cm_metastasis AS
(
  SELECT DISTINCT
    a.concept_name AS icd_name,
    a.concept_code AS icd_code,
    a.tumor_site_code,
    a.vocabulary_id AS icd_vocab,
    concept_id,
    s.concept_code,
    s.concept_name,
    s.vocabulary_id
  FROM icdoscript.similarity_tab s
  JOIN icdoscript.getherd_mts_codes a
    ON s.tumor_site_code = a.tumor_site_code
  WHERE similarity=1
);
-- Line 1108-1133:
--Assumption MTS
INSERT INTO icdoscript.icdo3_to_cm_metastasis (icd_name, icd_code, tumor_site_code, icd_vocab, concept_id, concept_code, concept_name, vocabulary_id)
SELECT DISTINCT
  s.concept_name AS icd_name,
  s.concept_code AS icd_code,
  SPLIT_PART(s.concept_code,'-',2) AS tumor_site_code,
  icd_code,
  m. concept_id,
  m.concept_code,
  m.concept_name,
  m.vocabulary_id
FROM icdoscript.concept_stage s
JOIN icdoscript.icdo3_to_cm_metastasis m
  ON SPLIT_PART(SPLIT_PART(s.concept_code,'-',2),'.',1)||'.9' = m.tumor_site_code
WHERE s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) AND s.concept_code LIKE '%/6-%';
-- Line 1134-1159:
-- Pathologically confirmed metastasis
INSERT INTO icdoscript.icdo3_to_cm_metastasis(icd_name, icd_code, tumor_site_code, icd_vocab, concept_id, concept_code, concept_name, vocabulary_id)
SELECT DISTINCT 
  s.concept_name AS icd_name,
  s.concept_code AS icd_code,
  SPLIT_PART(s.concept_code,'-',2),
  s.vocabulary_id AS icd_vocab,
  c. concept_id,
  c.concept_code,
  c.concept_name,
  c.vocabulary_id
FROM icdoscript.concept_stage s, omopcdm_jan24.concept  c
WHERE c.concept_code = 'OMOP4998770' AND c.vocabulary_id ='Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) 
AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('NULL','C80.9','C76.7');
-- Line 1160-1185:
--Assumption that the codes represent CTC
INSERT INTO icdoscript.icdo3_to_cm_metastasis(icd_name, icd_code, tumor_site_code, icd_vocab, concept_id, concept_code, concept_name, vocabulary_id)
SELECT DISTINCT 
  s.concept_name AS icd_name,
  s.concept_code AS icd_code,
  SPLIT_PART(s.concept_code,'-',2),
  s.vocabulary_id AS icd_vocab,
  c. concept_id,
  c.concept_code,
  c.concept_name,
  c.vocabulary_id
FROM icdoscript.concept_stage s, omopcdm_jan24.concept  c
WHERE c.concept_code = 'OMOP4999341' AND c.vocabulary_id ='Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)
AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) = 'C42.0';
-- Line 1186-1530:
--Hardcoded values (mostly LN stations)
INSERT INTO icdoscript.icdo3_to_cm_metastasis (icd_name, icd_code, tumor_site_code, icd_vocab, concept_id, concept_code, concept_name, vocabulary_id)
SELECT 
  icd_name,
  icd_code,
  tumor_site_code,
  icd_vocab,
  concept_id,
  concept_code,
  concept_name,
  vocabulary_id
FROM 
(
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2) AS tumor_site_code,
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031980' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) 
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C40.0', 'C47.1')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031483' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Metastasis to the Anal Canal
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C21')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031707' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) = 'C40.2'
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031839' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)--	Metastasis to the Retroperitoneum And Peritoneum'
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) = 'C48.8'
  UNION ALL
  SELECT DISTINCT
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031916' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Metastasis to the Soft Tissues
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) = 'C49.9'
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031618' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)--	Metastasis to the Female Genital Organ
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C57', 'C57.7')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031819' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Metastasis to the Prostate
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C61.9')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5031716' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Metastasis to the Male Genital Organ
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) in ('C63')
  UNION ALL 
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5117515' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Metastasis to meninges NEW CONCEPT
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C70', 'C70.9')  
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5117516' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --	Metastasis to abdomen --new concept
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C76.2')
  UNION ALL 
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --Lymph Nodes
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --Lymph Nodes -- TODO NEW CODE NEEDED (not sure that /6 resembles always distant)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.0')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --Lymph Nodes -- TODO NEW CODE NEEDED (not sure that /6 resembles always distant)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.1')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --Lymph Nodes -- TODO NEW CODE NEEDED (not sure that /6 resembles always distant)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) in ('C77.2')  
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --Lymph Nodes -- TODO NEW CODE NEEDED (not sure that /6 resembles always distant)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.2')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --Lymph Nodes -- TODO NEW CODE NEEDED (not sure that /6 resembles always distant)
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.3')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP5000384' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --	Inguinal Lymph Nodes
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.4')
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4999638' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis) --	Pelvic Lymph Nodes
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.5') 
  UNION ALL
  SELECT DISTINCT 
    s.concept_name AS icd_name,
    s.concept_code AS icd_code,
    SPLIT_PART(s.concept_code,'-',2),
    s.vocabulary_id AS icd_vocab,
    c.concept_id,
    c.concept_code,
    c.concept_name,
    c.vocabulary_id
  FROM icdoscript.concept_stage s, omopcdm_jan24.concept c
  WHERE c.concept_code = 'OMOP4998263' AND c.vocabulary_id = 'Cancer Modifier' AND s.concept_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis)  --Lymph Nodes
  AND s.concept_code LIKE '%/6-%' AND SPLIT_PART(s.concept_code,'-',2) IN ('C77.9')
) AS map
WHERE icd_code NOT IN (SELECT icd_code FROM icdoscript.icdo3_to_cm_metastasis);
UPDATE icdoscript.icdo3_to_cm_metastasis SET icd_vocab ='ICDO3' WHERE icd_vocab !='ICDO3';
-- Line 1531-1551:
--Insert into Concept_stage
INSERT INTO icdoscript.concept_relationship_stage(concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id, valid_start_date, valid_end_date)
SELECT DISTINCT
  icd_code AS concept_code_1 ,
  concept_code AS concept_code_2,
  icd_vocab AS vocabulary_id_1,
  vocabulary_id AS vocabulary_id_2,
  'Maps to' AS relationship_id,
  CURRENT_DATE AS valid_start_date,
  TO_DATE('20991231', 'yyyymmdd') AS valid_end_date
FROM icdoscript.icdo3_to_cm_metastasis;
-- Line 1552-1570:
-- Add this for later
ALTER TABLE icdoscript.concept_relationship_stage ADD CONSTRAINT idx_pk_crs PRIMARY KEY (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id);
--16.2. Check if there are manual 'Maps to' for perfectly processed concepts in manual table; we should get error if there are intersections
DO $_$
DECLARE
  codes text;
BEGIN
  SELECT
  	string_agg (m.concept_code_1, ''',''')
  INTO codes
  FROM sources.concept_relationship_manual m
  JOIN icdoscript.concept_relationship_stage s ON s.concept_code_1 = m.concept_code_1 AND s.vocabulary_id_1 = m.vocabulary_id_1 AND m.invalid_reason IS NULL AND m.relationship_id = 'Maps to';
  IF codes IS NOT NULL THEN
--    RAISE EXCEPTION 'Following codes need to be removed from manual table: ''%''', codes ;
	RAISE NOTICE 'Following codes need to be removed from manual table: ''%''', codes ;
  END IF;
END $_$;
-- Line 1571-1576:
-- First define the function (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/admin_pack/GetPrimaryRelationshipID.sql#L1)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION GetPrimaryRelationshipID (pRelationship_id TEXT) 
RETURNS TEXT AS
$BODY$
	/*
	Returns the 'correct' direction of mappings for the CheckManualRelationships function
	This prevents situations when medicals put the same relationship between the same concepts, only the first one put "direct" and the second - "reverse"
	*/
	WITH replacements
	AS (
			SELECT * FROM (VALUES 
				('Mapped from', 'Maps to'),
				('Subsumes', 'Is a'),
				('LOINC - CPT4 eq', 'CPT4 - LOINC eq'),
				('Schema to Value', 'Value to Schema'),
				('Answer of', 'Has Answer'),
				('Proc Schema to ICDO', 'ICDO to Proc Schema'),
				('Schema to Variable', 'Variable to Schema'),
				('Has precoord pair', 'Precoord pair of'),
				('Panel contains', 'Contained in panel'),
				('Schema to ICDO', 'ICDO to Schema'),
				('SNOMED - ATC eq', 'ATC - SNOMED eq'),
				('Answer of (PPI)', 'Has answer (PPI)')
			) AS r(incorrect_direction, correct_direction)
		)
	SELECT COALESCE(r.correct_direction, r1.relationship_id)
	FROM omopcdm_jan24.relationship r1
	JOIN omopcdm_jan24.relationship r2 ON r2.relationship_id = r1.reverse_relationship_id
		AND r2.relationship_concept_id > r1.relationship_concept_id
	LEFT JOIN replacements r ON r.incorrect_direction = r1.relationship_id
	WHERE pRelationship_id IN (
			r1.relationship_id,
			r1.reverse_relationship_id
			);
$BODY$
LANGUAGE 'sql' STABLE STRICT;
-- And (https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/packages/vocabulary_pack/CheckManualRelationships.sql):
-- With some minor modifications.
CREATE OR REPLACE FUNCTION CheckManualRelationships ()
RETURNS VOID AS
$BODY$
DECLARE
	z TEXT;
BEGIN
	SELECT s0.reason INTO z FROM (
		SELECT
			CASE WHEN c1.concept_code IS NULL AND cs1.concept_code IS NULL THEN 'concept_code_1+vocabulary_id_1 not found in the concept/concept_stage: "'||crm.concept_code_1||'"+"'||crm.vocabulary_id_1||'"'
				WHEN c2.concept_code IS NULL AND cs2.concept_code IS NULL THEN 'concept_code_2+vocabulary_id_2 not found in the concept/concept_stage: "'||crm.concept_code_2||'"+"'||crm.vocabulary_id_2||'"'
				WHEN v1.vocabulary_id IS NULL THEN 'vocabulary_id_1 not found in the vocabulary: "'||crm.vocabulary_id_1||'"'
				WHEN v2.vocabulary_id IS NULL THEN 'vocabulary_id_2 not found in the vocabulary: "'||crm.vocabulary_id_2||'"'
				WHEN rl.relationship_id IS NULL THEN 'relationship_id not found in the relationship: "'||crm.relationship_id||'"'
				WHEN crm.valid_start_date > CURRENT_DATE THEN 'valid_start_date is greater than the current date: '||TO_CHAR(crm.valid_start_date,'YYYYMMDD')
				WHEN crm.valid_end_date < crm.valid_start_date THEN 'valid_end_date < valid_start_date: '||TO_CHAR(crm.valid_end_date,'YYYYMMDD')||'+'||TO_CHAR(crm.valid_start_date,'YYYYMMDD')
				WHEN DATE_TRUNC('day', (crm.valid_start_date)) <> crm.valid_start_date THEN 'wrong format for valid_start_date (not truncated): '||TO_CHAR(crm.valid_start_date,'YYYYMMDD HH24:MI:SS')
				WHEN DATE_TRUNC('day', (crm.valid_end_date)) <> crm.valid_end_date THEN 'wrong format for valid_end_date (not truncated to YYYYMMDD): '||TO_CHAR(crm.valid_end_date,'YYYYMMDD HH24:MI:SS')
				WHEN ((crm.invalid_reason IS NULL AND crm.valid_end_date <> TO_DATE('20991231', 'yyyymmdd'))
					OR (crm.invalid_reason IS NOT NULL AND crm.valid_end_date = TO_DATE('20991231', 'yyyymmdd'))) THEN 'wrong invalid_reason: "'||COALESCE(crm.invalid_reason,'NULL')||'" for '||TO_CHAR(crm.valid_end_date,'YYYYMMDD')
				WHEN COALESCE(crm.invalid_reason, 'D') NOT IN ('D','U') THEN 'wrong value for invalid_reason: "'||crm.invalid_reason||'"'
				WHEN crm.relationship_id <> GetPrimaryRelationshipID(crm.relationship_id) THEN 'please use "'||GetPrimaryRelationshipID(crm.relationship_id)||'" instead of "'||crm.relationship_id||'"'
			END AS reason
		FROM sources.concept_relationship_manual crm
			LEFT JOIN omopcdm_jan24.concept c1 ON c1.concept_code = crm.concept_code_1 AND c1.vocabulary_id = crm.vocabulary_id_1
			LEFT JOIN icdoscript.concept_stage cs1 ON cs1.concept_code = crm.concept_code_1 AND cs1.vocabulary_id = crm.vocabulary_id_1
			LEFT JOIN omopcdm_jan24.concept c2 ON c2.concept_code = crm.concept_code_2 AND c2.vocabulary_id = crm.vocabulary_id_2
			LEFT JOIN icdoscript.concept_stage cs2 ON cs2.concept_code = crm.concept_code_2 AND cs2.vocabulary_id = crm.vocabulary_id_2
			LEFT JOIN omopcdm_jan24.vocabulary v1 ON v1.vocabulary_id = crm.vocabulary_id_1
			LEFT JOIN omopcdm_jan24.vocabulary v2 ON v2.vocabulary_id = crm.vocabulary_id_2
			LEFT JOIN omopcdm_jan24.relationship rl ON rl.relationship_id = crm.relationship_id
	) AS s0
	WHERE s0.reason IS NOT NULL
	LIMIT 1;

	IF FOUND THEN
		RAISE EXCEPTION '%', z;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';
-- And (https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/packages/vocabulary_pack/ProcessManualRelationships.sql)
-- With some major modifications.
CREATE OR REPLACE FUNCTION ProcessManualRelationships ()
RETURNS VOID AS
$BODY$
	/*
	Inserts a manual relationships from concept_relationship_manual into the concept_relationship_stage
	*/
--DECLARE
--	z INT4;
--	iSchemaName TEXT;
BEGIN
--	SELECT LOWER(MAX(v.dev_schema_name)), COUNT(DISTINCT v.dev_schema_name)
--	INTO iSchemaName, z
--	FROM omopcdm_jan24.vocabulary v;
----	WHERE v.latest_update IS NOT NULL; There is no column latest_update
--
--	IF z>1 THEN
--		RAISE EXCEPTION 'More than one dev_schema found';
--	END IF;
--
--	IF CURRENT_SCHEMA = 'devv5' THEN
--		TRUNCATE TABLE concept_relationship_manual;
--		EXECUTE FORMAT ($$
--			INSERT INTO concept_relationship_manual
--			SELECT crm.*
--			FROM %I.concept_relationship_manual crm
--			JOIN vocabulary v1 ON v1.vocabulary_id = crm.vocabulary_id_1
--			JOIN vocabulary v2 ON v2.vocabulary_id = crm.vocabulary_id_2
----			WHERE COALESCE(v1.latest_update, v2.latest_update) IS NOT NULL There is no column latest_update
--		$$, iSchemaName);
--	END IF;

	--checking concept_relationship_manual for errors
	PERFORM CheckManualRelationships();

	--add new records, update existing
	INSERT INTO icdoscript.concept_relationship_stage AS crs (
		concept_code_1,
		concept_code_2,
		vocabulary_id_1,
		vocabulary_id_2,
		relationship_id,
		valid_start_date,
		valid_end_date,
		invalid_reason
		)
	SELECT crm.*
	FROM sources.concept_relationship_manual crm
	JOIN omopcdm_jan24.vocabulary v1 ON v1.vocabulary_id = crm.vocabulary_id_1
	JOIN omopcdm_jan24.vocabulary v2 ON v2.vocabulary_id = crm.vocabulary_id_2
	WHERE COALESCE(v1.latest_update, v2.latest_update) IS NOT NULL 
	ON CONFLICT ON CONSTRAINT idx_pk_crs
	DO UPDATE
	SET valid_start_date = excluded.valid_start_date,
		valid_end_date = excluded.valid_end_date,
		invalid_reason = excluded.invalid_reason
	WHERE ROW (crs.valid_start_date, crs.valid_end_date, crs.invalid_reason)
	IS DISTINCT FROM
	ROW (excluded.valid_start_date, excluded.valid_end_date, excluded.invalid_reason);

END;
$BODY$
LANGUAGE 'plpgsql';
--16.3. Get mappings from manual table
DO $_$
BEGIN
	PERFORM ProcessManualRelationships();
END $_$;
-- Line 1577-1591:
--16.4. Write 'Is a' for everything else
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  m.i_code,
  m.s_id,
  'ICDO3',
  'SNOMED',
  'Is a',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.match_blob m
LEFT JOIN icdoscript.concept_relationship_stage r 
  ON m.i_code = r.concept_code_1
WHERE r.concept_code_1 IS NULL;
-- Line 1592-1611:
--17. Write relations for attributes
--17.1. Maps to
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  concept_code,
  snomed_code,
  'ICDO3',
  'SNOMED',
  'Maps to',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM sources.r_to_c_all	
LEFT JOIN icdoscript.code_replace 
  ON old_code = concept_code
WHERE old_code IS NULL AND snomed_code != '-1' AND relationship_id = 'Maps to' AND COALESCE (precedence,1) = 1;
-- Line 1612-1630:
--17.2. Is a
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  concept_code,
  snomed_code,
  'ICDO3',
  'SNOMED',
  'Is a',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM sources.r_to_c_all	
WHERE concept_code NOT IN
  (
    SELECT concept_code_1
    FROM icdoscript.concept_relationship_stage
  ) 
  AND concept_code != '9999/9' 
  AND snomed_code != '-1';
-- Line 1631-1633:
--18. Create internal hierarchy for attributes and combos
DROP TABLE IF EXISTS icdoscript.attribute_hierarchy;
-- Line 1634-1691: In steps
-- Step 1:
CREATE TABLE icdoscript.hierarchy AS
(
  SELECT
    level, -- 2 and 3
    icdo32 as concept_code,
    SUBSTRING (icdo32, '^\d{3}') AS start_code,
    SUBSTRING (icdo32, '\d{3}$') AS end_code
  FROM sources.morph_source_who 
  JOIN icdoscript.concept_stage 
    ON concept_code = icdo32
  WHERE level IN ('2','3')
);
-- Step 2:
CREATE TABLE icdoscript.relation_hierarchy AS
--Level 3 should be included in 2
(
  SELECT
    h3.concept_code AS descendant_code,
    h2.concept_code AS ancestor_code,
    'H' AS reltype --Hierarchy	
  FROM icdoscript.hierarchy h2
  JOIN icdoscript.hierarchy h3 
    ON h2.level = '2' AND h3.level = '3' AND h2.start_code <= h3.start_code AND h2.end_code || 'Z' >= h3.end_code -- to guarantee inclusion of upper bound
);
-- Step 3:
CREATE TABLE icdoscript.relation_atom AS
(
  SELECT
    s.concept_code AS descendant_code,
    h.concept_code AS ancestor_code,
    'A' AS reltype --Atom			
  FROM icdoscript.concept_stage s
  JOIN icdoscript.hierarchy h 
    ON s.concept_code BETWEEN h.start_code AND h.end_code || 'Z' -- to guarantee inclusion of upper bound
  WHERE s.concept_class_id = 'ICDO Histology' AND s.concept_code NOT IN (SELECT old_code FROM icdoscript.code_replace) AND s.standard_concept IS NULL 
    --avoid jump from 2 to atom where 3 is available; concept_ancestor will not care
	AND h.concept_code NOT IN (SELECT ancestor_code FROM icdoscript.relation_hierarchy)
    --obviously excludde hierarchical concepts
    AND s.concept_code NOT IN (SELECT concept_code FROM icdoscript.hierarchy)
);
-- Step 4:
CREATE TABLE icdoscript.attribute_hierarchy AS
SELECT *
FROM icdoscript.relation_hierarchy
  UNION ALL
SELECT *
FROM icdoscript.relation_atom;
-- Line 1692-1711:
--18.2. Internal hierarchy for topography attribute
INSERT INTO icdoscript.attribute_hierarchy
SELECT
  t1.code,
  t2.code,
  'A'
FROM sources.topo_source_iacr t1
JOIN sources.topo_source_iacr t2 
  ON t1.code LIKE '%.%' AND t2.code NOT LIKE '%.%' AND t1.code LIKE t2.code || '.%';
-- Line 1712-1724:
--19. Write 'Is a' for hierarchical concepts
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  ancestor_code,
  descendant_code,
  'ICDO3',
  'ICDO3',
  'Subsumes',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.attribute_hierarchy a
WHERE a.ancestor_code != a.descendant_code;
-- Line 1725-1741:
--20. Form internal relations (to attributes)
--write internal relations
--20.1. Histology
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  c1.concept_code,
  c1.histology_behavior,
  'ICDO3',
  'ICDO3',
  'Has Histology ICDO',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.comb_table c1
LEFT JOIN icdoscript.code_replace c2 
  ON C2.old_code = c1.concept_code
WHERE c2.old_code IS NULL;
-- Line 1742-1758:
--20.2. Topography
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  c1.concept_code,
  c1.site,
  'ICDO3',
  'ICDO3',
  'Has Topography ICDO',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.comb_table c1
LEFT JOIN icdoscript.code_replace c2 
  ON c2.old_code = c1.concept_code
WHERE c2.old_code IS NULL AND c1.site != '-1';
-- Line 1759-1787:
--20.3. Standard conditions should have 'Has asso morph' & 'Has finding site' from SNOMED parents
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
  s.concept_code,
  o.concept_code,
  'ICDO3',
  'SNOMED',
  a.relationship_id,
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.concept_stage s
JOIN icdoscript.concept_relationship_stage r 
  ON s.concept_class_id = 'ICDO Condition' AND r.concept_code_1 = s.concept_code AND r.relationship_id = 'Is a'
JOIN omopcdm_jan24.concept t 
  ON t.concept_code = r.concept_code_2 AND t.vocabulary_id = 'SNOMED'
JOIN omopcdm_jan24.concept_relationship a 
  ON a.invalid_reason IS NULL AND a.concept_id_1 = t.concept_id AND a.relationship_id IN ('Has asso morph',	'Has finding site')
JOIN omopcdm_jan24.concept o 
  ON o.concept_id = a.concept_id_2;
-- Line 1788-1845:
--20.4. Add own attributes to standard conditions
---Topography
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT
  s.concept_code,
  r1.snomed_code,
  'ICDO3',
  'SNOMED',
  'Has finding site',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.comb_table s
LEFT JOIN icdoscript.concept_relationship_stage x  
  ON s.concept_code = x.concept_code_1 AND x.relationship_id = 'Maps to' -- no mapping for condition
JOIN sources.r_to_c_all r1 
  ON s.site = r1.concept_code
WHERE x.concept_code_1 IS NULL AND r1.snomed_code != '-1' AND NOT EXISTS (SELECT 1 FROM icdoscript.concept_relationship_stage a WHERE a.concept_code_1 = s.concept_code AND a.concept_code_2 = r1.snomed_code::text)
  UNION ALL
---Histology
SELECT
  s.concept_code,
  r1.snomed_code,
  'ICDO3',
  'SNOMED',
  'Has asso morph',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.comb_table s
LEFT JOIN icdoscript.concept_relationship_stage x 
  ON s.concept_code = x.concept_code_1 AND x.relationship_id = 'Maps to' -- no mapping for condition
JOIN sources.r_to_c_all r1 
  ON s.histology_behavior = r1.concept_code AND	COALESCE (r1.precedence,1) = 1
WHERE x.concept_code_1 IS NULL AND r1.snomed_code != '-1' AND NOT EXISTS (SELECT 1 FROM icdoscript.concept_relationship_stage a WHERE a.concept_code_1 = s.concept_code AND a.concept_code_2 = r1.snomed_code::text);
-- Line 1846-1867:
--20.5. remove co-occurrent parents of target attributes (consider our concepts fully defined)
--DELETE FROM icdoscript.concept_relationship_stage s
--WHERE relationship_id IN ('Has asso morph','Has finding site')
--AND EXISTS
--(
--  SELECT
--  FROM icdoscript.concept_relationship_stage s2
--  JOIN omopcdm_jan24.concept cd 
--    ON s2.concept_code_2 = cd.concept_code AND cd.vocabulary_id = 'SNOMED' AND s2.concept_code_1 = s.concept_code_1 AND s.relationship_id = s2.relationship_id
--  JOIN icdoscript.snomed_ancestor a 
--    ON cd.concept_code = a.descendant_concept_code::text AND a.descendant_concept_code != a.ancestor_concept_code
--  JOIN omopcdm_jan24.concept ca 
--    ON ca.concept_code = a.ancestor_concept_code::text AND ca.concept_code = s.concept_code_2 AND ca.vocabulary_id = 'SNOMED'
--);
-- Script takes too long so we split it up:
-- Step 1:
CREATE TABLE icdoscript.tmp1 AS
(
  SELECT
    s2.concept_code_1 AS s2_concept_code_1,
    s2.relationship_id AS s2_relationship_id,
    ca.concept_code AS ca_concept_code
  FROM icdoscript.concept_relationship_stage s2
  JOIN omopcdm_jan24.concept cd 
    ON s2.concept_code_2 = cd.concept_code AND cd.vocabulary_id = 'SNOMED' 
  JOIN icdoscript.snomed_ancestor a 
    ON cd.concept_code = a.descendant_concept_code::text AND a.descendant_concept_code != a.ancestor_concept_code
  JOIN omopcdm_jan24.concept ca 
    ON ca.concept_code = a.ancestor_concept_code::text  AND ca.vocabulary_id = 'SNOMED'
 );
-- Step 2:
DELETE FROM icdoscript.concept_relationship_stage s
WHERE relationship_id IN ('Has asso morph','Has finding site')
AND EXISTS
(
  SELECT
  FROM icdoscript.tmp1 t1
  WHERE t1.s2_concept_code_1 = s.concept_code_1 AND s.relationship_id = t1.s2_relationship_id AND t1.ca_concept_code = s.concept_code_2
);
DROP TABLE icdoscript.tmp1;
-- Line 1868-1880:
--21. Handle replacements and self-mappings
--Add replacements from code_replace
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT DISTINCT
	old_code,
	code,
	'ICDO3',
	'ICDO3',
	'Concept replaced by',
	TO_DATE ('19700101', 'yyyymmdd'),
	TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.code_replace cr;
-- Line 1881-1897:
--22. Make concepts without 'Maps to' relations Standard
UPDATE icdoscript.concept_stage
SET standard_concept = 'S'
WHERE invalid_reason IS NULL AND concept_code NOT IN (SELECT concept_code_1 from icdoscript.concept_relationship_stage WHERE relationship_id = 'Maps to') 
AND (concept_class_id = 'ICDO Condition' OR (concept_class_id = 'ICDO Topography' AND concept_code LIKE '%.%') OR (concept_class_id = 'ICDO Histology' AND concept_code LIKE '%/%'));
-- Line 1898-1913:
--23. Populate concept_synonym_stage
--23.1. with morphologies
--we ignore obsoletion status of synonyms for now: concepts may still be referenced by their old names in historical classifications
--ICDO3 does not distinguish between 'old' and 'wrong'
INSERT INTO icdoscript.concept_synonym_stage
SELECT
  NULL,
  TRIM(term),
  icdo32,
  'ICDO3',
  4180186 -- English
FROM sources.morph_source_who
WHERE level != 'Related' AND icdo32 IS NOT NULL;-- not actual synonyms
-- Line 1914-1920:
-- First define the function (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/vocabulary_pack/CheckReplacementMappings.sql)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION CheckReplacementMappings ()
RETURNS VOID AS
$BODY$
/*
	Working with 'Concept replaced by', 'Concept same_as to', etc mappings:
	1. Delete duplicate replacement mappings (one concept has multiply target concepts)
	2. Delete self-connected mappings ("A 'Concept replaced by' B" and "B 'Concept replaced by' A")
	3. Deprecate concepts if we have no active replacement record in the concept_relationship_stage
	4. Deprecate replacement records if target concept was depreceted
	5. Deprecate concepts if we have no active replacement record in the concept_relationship_stage (yes, again)
*/
BEGIN
	--Delete duplicate replacement mappings (one concept has multiply target concepts)
	DELETE
	FROM icdoscript.concept_relationship_stage
	WHERE (
			concept_code_1,
			relationship_id
			) IN (
			SELECT concept_code_1,
				relationship_id
			FROM icdoscript.concept_relationship_stage
			WHERE relationship_id IN (
					'Concept replaced by',
					'Concept same_as to',
					'Concept alt_to to',
					'Concept was_a to'
					)
				AND invalid_reason IS NULL
			GROUP BY concept_code_1,
				relationship_id
			HAVING COUNT(DISTINCT concept_code_2) > 1
			);

	--Delete self-connected mappings ("A 'Concept replaced by' B" and "B 'Concept replaced by' A")
	DELETE
	FROM icdoscript.concept_relationship_stage crs
	WHERE EXISTS (
			SELECT 1
			FROM icdoscript.concept_relationship_stage cs1,
				icdoscript.concept_relationship_stage cs2
			WHERE cs1.invalid_reason IS NULL
				AND cs2.invalid_reason IS NULL
				AND cs1.concept_code_1 = cs2.concept_code_2
				AND cs1.concept_code_2 = cs2.concept_code_1
				AND cs1.vocabulary_id_1 = cs2.vocabulary_id_2
				AND cs1.vocabulary_id_2 = cs2.vocabulary_id_1
				AND cs1.relationship_id IN (
					'Concept replaced by',
					'Concept same_as to',
					'Concept alt_to to',
					'Concept was_a to'
					)
				AND cs2.relationship_id IN (
					'Concept replaced by',
					'Concept same_as to',
					'Concept alt_to to',
					'Concept was_a to'
					)
				AND crs.concept_code_1 = cs1.concept_code_1
				AND crs.concept_code_2 = cs1.concept_code_2
				AND crs.relationship_id = cs1.relationship_id
			);

	--Deprecate concepts if we have no active replacement record in the concept_relationship_stage
	UPDATE icdoscript.concept_stage cs
	SET valid_end_date = LEAST(cs.valid_end_date, v.latest_update - 1),
--	SET valid_end_date = cs.valid_end_date,
		invalid_reason = 'D',
		standard_concept = NULL
	FROM omopcdm_jan24.vocabulary v
	WHERE v.vocabulary_id = cs.vocabulary_id
		AND NOT EXISTS (
			SELECT 1
			FROM icdoscript.concept_relationship_stage crs
			WHERE crs.concept_code_1 = cs.concept_code
				AND crs.vocabulary_id_1 = cs.vocabulary_id
				AND crs.invalid_reason IS NULL
				AND crs.relationship_id IN (
					'Concept replaced by',
					'Concept same_as to',
					'Concept alt_to to',
					'Concept was_a to'
					)
			)
		AND cs.invalid_reason = 'U';

	WITH t
	AS (
		WITH RECURSIVE rec AS (
				SELECT u.concept_code_1,
					u.vocabulary_id_1,
					u.concept_code_2,
					u.vocabulary_id_2,
					u.relationship_id,
					ARRAY [u.concept_code_2::text] AS full_path
				FROM upgraded_concepts u
				WHERE EXISTS (
						SELECT 1
						FROM upgraded_concepts u_int
						WHERE u_int.invalid_reason = 'D'
							AND u_int.concept_code_2 = u.concept_code_2
						)
				
				UNION ALL
				
				SELECT uc.concept_code_1,
					uc.vocabulary_id_1,
					uc.concept_code_2,
					uc.vocabulary_id_2,
					uc.relationship_id,
					r.full_path || uc.concept_code_2::TEXT AS full_path
				FROM upgraded_concepts uc
				JOIN rec r ON r.concept_code_1 = uc.concept_code_2
				WHERE uc.concept_code_2 <> ALL (full_path)
				),
			upgraded_concepts AS (
				SELECT crs.concept_code_1,
					crs.vocabulary_id_1,
					crs.concept_code_2,
					crs.vocabulary_id_2,
					crs.relationship_id,
					CASE 
						WHEN COALESCE(cs.concept_code, c.concept_code) IS NULL
							THEN 'D'
						ELSE CASE 
								WHEN cs.concept_code IS NOT NULL
									THEN cs.invalid_reason
								ELSE c.invalid_reason
								END
						END AS invalid_reason
				FROM icdoscript.concept_relationship_stage crs
				LEFT JOIN icdoscript.concept_stage cs ON crs.concept_code_2 = cs.concept_code
					AND crs.vocabulary_id_2 = cs.vocabulary_id
				LEFT JOIN omopcdm_jan24.concept c ON crs.concept_code_2 = c.concept_code
					AND crs.vocabulary_id_2 = c.vocabulary_id
				WHERE crs.relationship_id IN (
						'Concept replaced by',
						'Concept same_as to',
						'Concept alt_to to',
						'Concept was_a to'
						)
					AND crs.concept_code_1 <> crs.concept_code_2
					AND crs.invalid_reason IS NULL
				)
		SELECT concept_code_1,
			vocabulary_id_1,
			concept_code_2,
			vocabulary_id_2,
			relationship_id
		FROM rec
		)
	UPDATE icdoscript.concept_relationship_stage crs
	SET invalid_reason = 'D',
		valid_end_date = GREATEST(valid_start_date, (
				SELECT MAX(latest_update) - 1
				FROM omopcdm_jan24.vocabulary
				WHERE vocabulary_id IN (
						crs.vocabulary_id_1,
						crs.vocabulary_id_2
						)
				))
--		valid_end_date = valid_start_date
	FROM t
	WHERE crs.concept_code_1 = t.concept_code_1
		AND crs.vocabulary_id_1 = t.vocabulary_id_1
		AND crs.concept_code_2 = t.concept_code_2
		AND crs.vocabulary_id_2 = t.vocabulary_id_2
		AND crs.relationship_id = t.relationship_id;

	--Deprecate concepts if we have no active replacement record in the concept_relationship_stage (yes, again)
	UPDATE icdoscript.concept_stage cs
	SET valid_end_date = LEAST(cs.valid_end_date, v.latest_update - 1),
--	SET valid_end_date = cs.valid_end_date,	
		invalid_reason = 'D',
		standard_concept = NULL
	FROM omopcdm_jan24.vocabulary v
	WHERE v.vocabulary_id = cs.vocabulary_id
		AND NOT EXISTS (
			SELECT 1
			FROM icdoscript.concept_relationship_stage crs
			WHERE crs.concept_code_1 = cs.concept_code
				AND crs.vocabulary_id_1 = cs.vocabulary_id
				AND crs.invalid_reason IS NULL
				AND crs.relationship_id IN (
					'Concept replaced by',
					'Concept same_as to',
					'Concept alt_to to',
					'Concept was_a to'
					)
			)
		AND cs.invalid_reason = 'U';
END;
$BODY$
LANGUAGE 'plpgsql';
--24. Vocabulary pack procedures
--24.1. Working with replacement mappings
DO $_$
BEGIN
	PERFORM CheckReplacementMappings();
END $_$;
-- Line 1921-1950:
--25.2, Add mapping from deprecated to fresh concepts -- Disabled - breaks Upgraded concepts
/*DO $_$
BEGIN
	PERFORM VOCABULARY_PACK.AddFreshMAPSTO();
END $_$;*/
--do this instead:
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date)
SELECT
  r.concept_code_1,
  COALESCE (r2.concept_code_2, r.concept_code_2),
  r.vocabulary_id_1,
  COALESCE (r2.vocabulary_id_2, r.vocabulary_id_2),
  'Maps to',
  TO_DATE ('19700101', 'yyyymmdd'),
  TO_DATE ('20991231', 'yyyymmdd')
FROM icdoscript.concept_relationship_stage r
LEFT JOIN icdoscript.concept_relationship_stage r2 
ON r2.relationship_id = 'Maps to' AND r.concept_code_2 = r2.concept_code_1
WHERE r.relationship_id = 'Concept replaced by' AND NOT EXISTS (SELECT 1 FROM icdoscript.concept_relationship_stage r3 WHERE r.concept_code_1 = r3.concept_code_1 AND r3.relationship_id = 'Maps to');
-- Line 1951-1956:
-- First create type concept (not sure where that happens in the original code).
DROP TYPE IF EXISTS concept CASCADE;
CREATE TYPE concept AS
(
  concept_id integer,
  concept_name varchar(255),
  domain_id varchar(20),
  vocabulary_id varchar(20),
  concept_class_id varchar(20),
  standard_concept varchar(1),
  concept_code varchar(50),
  valid_start_date date,
  valid_end_date date,
  invalid_reason varchar(1)
);
-- First define the function (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/vocabulary_pack/GetActualConceptInfo.sql)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION GetActualConceptInfo (pConceptCode TEXT, pVocabularyID TEXT)
RETURNS SETOF concept AS
$BODY$
	/*
	 Get actual information about a concept in the following order: concept_stage, concept
	*/
	SELECT s0.concept_id,
		s0.concept_name,
		s0.domain_id,
		s0.vocabulary_id,
		s0.concept_class_id,
		s0.standard_concept,
		s0.concept_code,
		s0.valid_start_date,
		s0.valid_end_date,
		s0.invalid_reason
	FROM (
		SELECT cs.*
		FROM icdoscript.concept_stage cs
		WHERE cs.concept_code = pConceptCode
			AND cs.vocabulary_id = pVocabularyID
		
		UNION ALL
		
		SELECT c.*
		FROM omopcdm_jan24.concept c
		WHERE c.concept_code = pConceptCode
			AND c.vocabulary_id = pVocabularyID
		) AS s0
	LIMIT 1;
$BODY$
LANGUAGE 'sql' STABLE STRICT;
-- And (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/vocabulary_pack/DeprecateWrongMapsTo.sql)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION DeprecateWrongMapsTo ()
RETURNS VOID AS
$BODY$
	/*
	 Deprecates 'Maps to' mappings to deprecated ('D') and upgraded ('U') concepts
	*/
BEGIN
	UPDATE icdoscript.concept_relationship_stage crs
	SET valid_end_date = GREATEST(crs.valid_start_date, (
				SELECT MAX(v.latest_update) - 1
				FROM omopcdm_jan24.vocabulary v
				WHERE v.vocabulary_id IN (
						crs.vocabulary_id_1,
						crs.vocabulary_id_2
						)
				)),
--	SET valid_end_date = crs.valid_start_date,
		invalid_reason = 'D'
	WHERE crs.relationship_id = 'Maps to'
		AND crs.invalid_reason IS NULL
		AND EXISTS (
				--check if target concept is non-valid (first in concept_stage, then concept)
				SELECT 1
				FROM GetActualConceptInfo(crs.concept_code_2, crs.vocabulary_id_2) a
				WHERE a.invalid_reason IN (
						'U',
						'D'
						)
				);
END;
$BODY$
LANGUAGE 'plpgsql';
--25.3. Deprecate 'Maps to' mappings to deprecated and upgraded concepts
DO $_$
BEGIN
	PERFORM DeprecateWrongMAPSTO();
END $_$;
-- Line 1957-1962:
-- First define the function (https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/vocabulary_pack/DeleteAmbiguousMapsTo.sql)
-- With some minor modifications.
CREATE OR REPLACE FUNCTION DeleteAmbiguousMAPSTO ()
RETURNS VOID AS
$BODY$
	/*
	 Deprecate ambiguous 'Maps to' mappings following by rules:
	 1. if we have 'true' mappings to Ingredient or Clinical Drug Comp, then deprecate all others mappings
	 2. if we don't have 'true' mappings, then leave only one fresh mapping
	 3. if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then deprecate mappings to Ingredients, which have mappings to Clinical Drug Comp
	*/
BEGIN
	ANALYZE icdoscript.concept_relationship_stage, icdoscript.concept_stage;
	
	CREATE TEMP TABLE has_rel_with_comp ON COMMIT DROP AS
		SELECT crs_int2.concept_code_1,
			crs_int2.vocabulary_id_1,
			crs_int1.concept_code_1 AS concept_code_2,
			crs_int1.vocabulary_id_1 AS vocabulary_id_2
		FROM icdoscript.concept_relationship_stage crs_int1
		JOIN icdoscript.concept_relationship_stage crs_int2 ON crs_int2.concept_code_2 = crs_int1.concept_code_2
			AND crs_int2.vocabulary_id_2 = crs_int1.vocabulary_id_2
			AND crs_int2.relationship_id = 'Maps to'
			AND crs_int2.invalid_reason IS NULL
		JOIN icdoscript.concept_stage cs_int ON cs_int.concept_code = crs_int1.concept_code_2
			AND cs_int.vocabulary_id = crs_int1.vocabulary_id_2
			AND cs_int.domain_id = 'Drug'
			AND cs_int.concept_class_id = 'Clinical Drug Comp'
			AND cs_int.vocabulary_id LIKE 'Rx%'
		WHERE crs_int1.relationship_id = 'RxNorm ing of'
			AND crs_int1.invalid_reason IS NULL;

	CREATE TEMP TABLE ambiguous_mappings ON COMMIT DROP AS
		WITH mappings AS (
			SELECT s1.concept_code_1,
				s1.concept_code_2,
				s1.vocabulary_id_1,
				s1.vocabulary_id_2,
				s1.pseudo_class_id,
				s1.rn,
				MIN(s1.pseudo_class_id) OVER (
					PARTITION BY s1.concept_code_1,
					s1.vocabulary_id_1
					) have_true_mapping,
				s1.concept_class_id
			FROM (
				SELECT crs.concept_code_1,
					crs.concept_code_2,
					crs.vocabulary_id_1,
					crs.vocabulary_id_2,
					CASE 
						WHEN a.concept_class_id IN (
								'Ingredient',
								'Clinical Drug Comp'
								)
							THEN 1
						ELSE 2
						END pseudo_class_id,
					ROW_NUMBER() OVER (
						PARTITION BY crs.concept_code_1,
						crs.vocabulary_id_1 ORDER BY crs.valid_start_date DESC, --fresh mappings first
							CASE crs.vocabulary_id_2
								WHEN 'RxNorm'
									THEN 1
								ELSE 2
								END, --mappings to RxNorm first
							a.concept_id DESC,
							crs.concept_code_2 --if no concept_id found
						) rn,
					a.concept_class_id
				FROM icdoscript.concept_relationship_stage crs
				CROSS JOIN GetActualConceptInfo(crs.concept_code_2, crs.vocabulary_id_2) a
				WHERE crs.relationship_id = 'Maps to'
					AND crs.invalid_reason IS NULL
					AND crs.vocabulary_id_2 LIKE 'Rx%'
					AND a.domain_id = 'Drug'
				) AS s1
			)
		SELECT m.concept_code_1,
			m.concept_code_2,
			m.vocabulary_id_1,
			m.vocabulary_id_2
		FROM mappings m
		WHERE m.have_true_mapping = 1
			AND m.pseudo_class_id = 2 --if we have 'true' mappings to Ingredients or Clinical Drug Comps (pseudo_class_id=1), then deprecate all others mappings (pseudo_class_id=2)

		UNION ALL

		SELECT m.concept_code_1,
			m.concept_code_2,
			m.vocabulary_id_1,
			m.vocabulary_id_2
		FROM mappings m
		WHERE m.have_true_mapping <> 1
			AND m.rn > 1 --if we don't have 'true' mappings, then leave only one fresh mapping

		UNION ALL

		SELECT m.concept_code_1,
			m.concept_code_2,
			m.vocabulary_id_1,
			m.vocabulary_id_2
		FROM mappings m
		WHERE m.concept_class_id = 'Ingredient'
		--if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then deprecate mappings to Ingredients, which have mappings to Clinical Drug Comp
		AND EXISTS (
			SELECT 1
			FROM has_rel_with_comp h
			WHERE h.concept_code_1 = m.concept_code_1
				AND h.vocabulary_id_1 = m.vocabulary_id_1
				AND h.concept_code_2 = m.concept_code_2
				AND h.vocabulary_id_2 = m.vocabulary_id_2
		);

	UPDATE icdoscript.concept_relationship_stage crs
	SET invalid_reason = 'D',
		valid_end_date = GREATEST(crs.valid_start_date, (
				SELECT MAX(v.latest_update) - 1
				FROM omopcdm_jan24.vocabulary v
				WHERE v.vocabulary_id IN (
						crs.vocabulary_id_1,
						crs.vocabulary_id_2
						)
				))
--		valid_end_date = crs.valid_start_date
	FROM ambiguous_mappings am
	WHERE crs.concept_code_1 = am.concept_code_1
		AND crs.concept_code_2 = am.concept_code_2
		AND crs.vocabulary_id_1 = am.vocabulary_id_1
		AND crs.vocabulary_id_2 = am.vocabulary_id_2
		AND crs.relationship_id = 'Maps to'
		AND crs.invalid_reason IS NULL;

	--if the function is executed in a transaction, then by the time of the next call the temp table will exist
	DROP TABLE has_rel_with_comp, ambiguous_mappings;
END;
$BODY$
LANGUAGE 'plpgsql';
--25.4. Delete ambiguous 'Maps to' mappings
DO $_$
BEGIN
	PERFORM DeleteAmbiguousMAPSTO();
END $_$;
-- Line 1963-1977:
--26. If concept got replaced, give it invalid_reason = 'U'
UPDATE icdoscript.concept_stage x
SET invalid_reason = 'U'
WHERE invalid_reason = 'D' AND EXISTS (SELECT 1 FROM icdoscript.concept_relationship_stage WHERE invalid_reason IS NULL AND relationship_id = 'Concept replaced by' AND concept_code_1 = x.concept_code);
-- Line 1978-1987:
--27. Condition built from deprecated (not replaced) histologies need to have their validity period or invalid_reason modified
--27.1. invalid_reason => 'D'
UPDATE icdoscript.concept_stage
SET invalid_reason = 'D'
WHERE concept_class_id = 'ICDO Condition' AND standard_concept IS NULL AND valid_end_date < CURRENT_DATE AND invalid_reason IS NULL;
-- Line 1988-1996:
--28.2. end date => '20991231'
UPDATE icdoscript.concept_stage
SET valid_end_date = TO_DATE('20991231','yyyymmdd')
WHERE concept_class_id = 'ICDO Condition' AND standard_concept = 'S' AND	valid_end_date < CURRENT_DATE AND invalid_reason IS NULL;
-- Line 1997-2027:
--29. Since our relationship list is cannonically complete, we deprecate all existing relationships if they are not reinforced in current release
--29.1. From ICDO3 to SNOMED
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date, invalid_reason)
SELECT
  c.concept_code,
  c2.concept_code,
  'ICDO3',
  'SNOMED',
  r.relationship_id,
  r.valid_start_date,
-- There is no latest_update column in vocabulary
  (
    SELECT latest_update - 1
    FROM omopcdm_jan24.vocabulary
    WHERE latest_update IS NOT NULL
    LIMIT 1
  ),
--  CURRENT_DATE,
  'D'
FROM omopcdm_jan24.concept_relationship r
JOIN omopcdm_jan24.concept c 
  ON c.concept_id = r.concept_id_1 AND c.vocabulary_id = 'ICDO3' AND r.invalid_reason IS NULL
JOIN omopcdm_jan24.concept c2 
  ON c2.concept_id = r.concept_id_2 AND	c2.vocabulary_id = 'SNOMED'
LEFT JOIN icdoscript.concept_relationship_stage s 
  ON s.concept_code_1 = c.concept_code AND s.concept_code_2 = c2.concept_code AND s.relationship_id = r.relationship_id
 WHERE s.concept_code_1 IS NULL;
-- Line 2028-2092:
--29.2. From ICDO to ICDO
INSERT INTO icdoscript.concept_relationship_stage (concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date, invalid_reason)
WITH rela AS
--Ensure such relations were created this release (avoids mirroring problem)
(
  SELECT DISTINCT relationship_id
  FROM icdoscript.concept_relationship_stage
  WHERE vocabulary_id_1 = 'ICDO3' AND vocabulary_id_2 = 'ICDO3' AND invalid_reason IS NULL
)
SELECT
  c.concept_code,
  c2.concept_code,
  'ICDO3',
  'ICDO3',
  r.relationship_id,
  --Workaround for fixes between source releases
-- no latest_update column
  CASE 
  	WHEN r.valid_start_date <=
  	(
  		SELECT latest_update
  		FROM omopcdm_jan24.vocabulary
  		WHERE latest_update IS NOT NULL
  		LIMIT 1
  	)
  	THEN TO_DATE ('19700101', 'yyyymmdd')
  	ELSE r.valid_start_date		
  END,
--  TO_DATE ('19700101', 'yyyymmdd'),
-- no latest_update column
  (
  	SELECT latest_update - 1
  	FROM omopcdm_jan24.vocabulary
  	WHERE latest_update IS NOT NULL
  	LIMIT 1
  ),
--  CURRENT_DATE,
  'D'
FROM omopcdm_jan24.concept_relationship r
JOIN rela a 
  USING (relationship_id)
JOIN omopcdm_jan24.concept c 
  ON c.concept_id = r.concept_id_1 AND c.vocabulary_id = 'ICDO3' AND r.invalid_reason IS NULL
JOIN omopcdm_jan24.concept c2 
  ON c2.concept_id = r.concept_id_2 AND	c2.vocabulary_id = 'ICDO3'
LEFT JOIN icdoscript.concept_relationship_stage s 
  ON s.concept_code_1 = c.concept_code AND s.concept_code_2 = c2.concept_code AND s.relationship_id = r.relationship_id
WHERE s.concept_code_1 IS NULL AND NOT (c.concept_id = c2.concept_id AND r.relationship_id = 'Maps to' AND EXISTS (SELECT 1 FROM icdoscript.concept_stage x WHERE x.concept_code = c.concept_code));
--don't deprecate maps to self for Standard concepts
-- Line 2093-2095:
-- 30. Cleanup: drop all temporary tables
DROP TABLE IF EXISTS icdoscript.snomed_mapping, icdoscript.snomed_target_prepared, icdoscript.attribute_hierarchy, icdoscript.comb_table, icdoscript.match_blob, icdoscript.code_replace, icdoscript.snomed_ancestor, icdoscript.icdo3_to_cm_metastasis;
-- And our own intermediate tables
DROP TABLE IF EXISTS icdoscript.active_concept, icdoscript.def_status, icdoscript.getherd_mts_codes, icdoscript.hierarchy, icdoscript.monorelation;
DROP TABLE IF EXISTS icdoscript.relation_atom, icdoscript.relation_hierarchy, icdoscript.similarity_tab, icdoscript.snomed_concept, icdoscript.tabb, icdoscript.tabbc;