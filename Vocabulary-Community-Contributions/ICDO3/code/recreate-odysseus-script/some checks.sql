-----------------------------------------------------------------------------------------------------------------------------

-- Checks:
DROP TABLE IF EXISTS omopcdm_jan24.icdo3_concept;
CREATE TABLE omopcdm_jan24.icdo3_concept AS 
(
  SELECT *
  FROM omopcdm_jan24.concept
  WHERE vocabulary_id = 'ICDO3'
)
DROP TABLE IF EXISTS omopcdm_jan24.icdo3_concept_relationship;
CREATE TABLE omopcdm_jan24.icdo3_concept_relationship AS 
(
  SELECT 
    c1.concept_code AS concept_code_1,
	c2.concept_code AS concept_code_2,
	c1.vocabulary_id AS vocabulary_id_1,
	c2.vocabulary_id AS vocabulary_id_2,
	cr.relationship_id AS relationship_id,
	cr.valid_start_date AS valid_start_date,
	cr.valid_end_date AS valid_end_date,
	cr.invalid_reason AS invalid_reason
  FROM omopcdm_jan24.concept_relationship cr
  JOIN omopcdm_jan24.concept c1
  ON c1.concept_id = cr.concept_id_1
  JOIN omopcdm_jan24.concept c2
  ON c2.concept_id = cr.concept_id_2
  WHERE c1.vocabulary_id = 'ICDO3' OR c2.vocabulary_id = 'ICDO3'
)
-- Check 1:
SELECT COUNT(*)
FROM icdoscript.concept_stage cs
WHERE invalid_reason IS NULL
-- 63461 concepts -> 87932 (85746 valid)
SELECT COUNT(*)
FROM omopcdm_aug23.icdo3_concept ic
WHERE invalid_reason IS NULL
-- 64471 concepts (61479 valid)
-- Difference of 1010 (24267)
-- Check 2: Everything in concept_stage is in concept -> 24458 new valid concepts
SELECT *
FROM omopcdm_aug23.icdo3_concept ic
WHERE NOT EXISTS
(
  SELECT
  FROM icdoscript.concept_stage cs
  WHERE ic.concept_code = cs.concept_code AND cs.invalid_reason IS NULL
)
AND ic.invalid_reason IS NULL
-- Check 3: 1010 concepts are missing from concept_stage -> 191 valid concepts are missing (125 /6, 66 others (none are in input file, except ???)
SELECT *
FROM omopcdm_jan24.icdo3_concept ic
WHERE NOT EXISTS
(
  SELECT
  FROM icdoscript.concept_stage cs
  WHERE ic.concept_code = cs.concept_code
)
-- Check 4:
SELECT COUNT(*)
FROM icdoscript.concept_relationship_stage
-- 434134 relationships -> 626836 (478704 valid ones)
SELECT COUNT(*)
FROM omopcdm_jan24.icdo3_concept_relationship
-- 1192976 relationships (all valid)
-- Difference of 758842
-- Check 5: 29433 relationships in concept_relationship_stage are not in concept concept_relationship
SELECT *
FROM icdoscript.concept_relationship_stage crs
WHERE NOT EXISTS
(
  SELECT
  FROM omopcdm_jan24.icdo3_concept_relationship icr
  WHERE icr.concept_code_1 = crs.concept_code_1 AND icr.concept_code_2 = crs.concept_code_2 AND icr.vocabulary_id_1 = crs.vocabulary_id_1 AND icr.vocabulary_id_2 = crs.vocabulary_id_2 AND icr.relationship_id = crs.relationship_id
)
-- Check 6: 788275 relationships in concept_relationship are not in concept concept_relationship_stage
SELECT *
FROM omopcdm_jan24.icdo3_concept_relationship icr
WHERE NOT EXISTS
(
  SELECT
  FROM icdoscript.concept_relationship_stage crs
  WHERE icr.concept_code_1 = crs.concept_code_1 AND icr.concept_code_2 = crs.concept_code_2 AND icr.vocabulary_id_1 = crs.vocabulary_id_1 AND icr.vocabulary_id_2 = crs.vocabulary_id_2 AND icr.relationship_id = crs.relationship_id
)