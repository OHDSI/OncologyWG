-- Drop schema and dependencies
DROP SCHEMA IF EXISTS sources CASCADE;
CREATE SCHEMA IF NOT EXISTS sources;

-- Create tables
CREATE TABLE sources.r_to_c_all(
  concept_code VARCHAR(50) NOT NULL,
  concept_name VARCHAR(255) NOT NULL,	
  relationship_id VARCHAR(20) NOT NULL,	
  snomed_code BIGINT NOT NULL, 
  precedence INT
);

CREATE TABLE sources.topo_source_iacr(
  source_string VARCHAR(255),
  code VARCHAR(50),
  concept_name VARCHAR(255)	
);

CREATE TABLE sources.morph_source_who(
  icdo32 VARCHAR(50),
  level VARCHAR(50),
  term VARCHAR(255),
  code_reference VARCHAR(50),
  obs VARCHAR(50)
);

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

CREATE TABLE sources.icdo3_valid_combination(
  histology_behavior VARCHAR(10),
  site VARCHAR(10)
);

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

-- Load data
DROP FUNCTION IF EXISTS copyif;

CREATE FUNCTION copyif(tablename text, filename text) RETURNS VOID AS
$func$
BEGIN
EXECUTE (
  format('DO
  $do$
  BEGIN
  IF NOT EXISTS (SELECT FROM %s) THEN
	 COPY %s FROM ''%s'' WITH DELIMITER E''\t'' CSV HEADER QUOTE ''"'' ;
  END IF;
  END
  $do$
', tablename, tablename, filename));
END
$func$ LANGUAGE plpgsql;

-- SELECT copyif('sources.r_to_c_all',                  'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/r_to_c_all.csv');
SELECT copyif('sources.r_to_c_all',                  'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/updated input files jan24 release/r_to_c_all.csv');
SELECT copyif('sources.concept_manual',              'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/concept_manual.csv');
-- SELECT copyif('sources.concept_relationship_manual', 'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/concept_relationship_manual.csv');
SELECT copyif('sources.concept_relationship_manual', 'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/updated input files jan24 release/concept_relationship_manual.csv');

DROP FUNCTION IF EXISTS copyif;

CREATE FUNCTION copyif(tablename text, filename text) RETURNS VOID AS
$func$
BEGIN
EXECUTE (
  format('DO
  $do$
  BEGIN
  IF NOT EXISTS (SELECT FROM %s) THEN
	 COPY %s FROM ''%s'' WITH DELIMITER E'','' CSV HEADER QUOTE '''''''' ;
  END IF;
  END
  $do$
', tablename, tablename, filename));
END
$func$ LANGUAGE plpgsql;

SELECT copyif('sources.topo_source_iacr',            'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/topo_source_iacr.csv');
SELECT copyif('sources.morph_source_who',            'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/morph_source_who.csv');
SELECT copyif('sources.icdo3_valid_combination',     'C:/Archives/OncologyWG/Vocabulary-Community-Contributions/ICDO3/code/recreate-odysseus-script/original input files/icdo3_valid_combination.csv');