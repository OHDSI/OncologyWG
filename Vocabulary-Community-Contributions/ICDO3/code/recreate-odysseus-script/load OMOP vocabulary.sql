-- Drop schema and dependencies
DROP SCHEMA IF EXISTS omopcdm CASCADE;
CREATE SCHEMA IF NOT EXISTS omopcdm;

-- Create tables
--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.CONCEPT (
			concept_id integer NOT NULL,
			concept_name varchar(255) NOT NULL,
			domain_id varchar(20) NOT NULL,
			vocabulary_id varchar(20) NOT NULL,
			concept_class_id varchar(20) NOT NULL,
			standard_concept varchar(1) NULL,
			concept_code varchar(50) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.VOCABULARY (
			vocabulary_id varchar(20) NOT NULL,
			vocabulary_name varchar(255) NOT NULL,
			vocabulary_reference varchar(255) NULL,
			vocabulary_version varchar(255) NULL,
			vocabulary_concept_id integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.DOMAIN (
			domain_id varchar(20) NOT NULL,
			domain_name varchar(255) NOT NULL,
			domain_concept_id integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.CONCEPT_CLASS (
			concept_class_id varchar(20) NOT NULL,
			concept_class_name varchar(255) NOT NULL,
			concept_class_concept_id integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.CONCEPT_RELATIONSHIP (
			concept_id_1 integer NOT NULL,
			concept_id_2 integer NOT NULL,
			relationship_id varchar(20) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.RELATIONSHIP (
			relationship_id varchar(20) NOT NULL,
			relationship_name varchar(255) NOT NULL,
			is_hierarchical varchar(1) NOT NULL,
			defines_ancestry varchar(1) NOT NULL,
			reverse_relationship_id varchar(20) NOT NULL,
			relationship_concept_id integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.CONCEPT_SYNONYM (
			concept_id integer NOT NULL,
			concept_synonym_name varchar(1000) NOT NULL,
			language_concept_id integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.CONCEPT_ANCESTOR (
			ancestor_concept_id integer NOT NULL,
			descendant_concept_id integer NOT NULL,
			min_levels_of_separation integer NOT NULL,
			max_levels_of_separation integer NOT NULL );

--HINT DISTRIBUTE ON RANDOM
 CREATE TABLE IF NOT EXISTS  omopcdm.DRUG_STRENGTH (
			drug_concept_id integer NOT NULL,
			ingredient_concept_id integer NOT NULL,
			amount_value NUMERIC NULL,
			amount_unit_concept_id integer NULL,
			numerator_value NUMERIC NULL,
			numerator_unit_concept_id integer NULL,
			denominator_value NUMERIC NULL,
			denominator_unit_concept_id integer NULL,
			box_size integer NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );
	
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
     COPY %s FROM ''%s'' WITH DELIMITER E''\t'' CSV HEADER QUOTE E''\b'' ;
  END IF;
  END
  $do$
', tablename, tablename, filename));
END
$func$ LANGUAGE plpgsql;

SELECT copyif('omopcdm.DRUG_STRENGTH',        'C:/Data/OHDSI/vocabularies/vocab_feb24/DRUG_STRENGTH.csv');
SELECT copyif('omopcdm.CONCEPT',              'C:/Data/OHDSI/vocabularies/vocab_feb24/CONCEPT.csv');
SELECT copyif('omopcdm.CONCEPT_RELATIONSHIP', 'C:/Data/OHDSI/vocabularies/vocab_feb24/CONCEPT_RELATIONSHIP.csv');
SELECT copyif('omopcdm.CONCEPT_ANCESTOR',     'C:/Data/OHDSI/vocabularies/vocab_feb24/CONCEPT_ANCESTOR.csv');
SELECT copyif('omopcdm.CONCEPT_SYNONYM',      'C:/Data/OHDSI/vocabularies/vocab_feb24/CONCEPT_SYNONYM.csv');
SELECT copyif('omopcdm.RELATIONSHIP',         'C:/Data/OHDSI/vocabularies/vocab_feb24/RELATIONSHIP.csv');
SELECT copyif('omopcdm.CONCEPT_CLASS',        'C:/Data/OHDSI/vocabularies/vocab_feb24/CONCEPT_CLASS.csv');
SELECT copyif('omopcdm.DOMAIN',               'C:/Data/OHDSI/vocabularies/vocab_feb24/DOMAIN.csv');
SELECT copyif('omopcdm.VOCABULARY',           'C:/Data/OHDSI/vocabularies/vocab_feb24/VOCABULARY.csv');

-- Create primary keys
ALTER TABLE omopcdm.CONCEPT ADD CONSTRAINT xpk_concept PRIMARY KEY (concept_id);
ALTER TABLE omopcdm.VOCABULARY ADD CONSTRAINT xpk_vocabulary PRIMARY KEY (vocabulary_id);
ALTER TABLE omopcdm.DOMAIN ADD CONSTRAINT xpk_domain PRIMARY KEY (domain_id);
ALTER TABLE omopcdm.CONCEPT_CLASS ADD CONSTRAINT xpk_concept_class PRIMARY KEY (concept_class_id);
ALTER TABLE omopcdm.RELATIONSHIP ADD CONSTRAINT xpk_relationship PRIMARY KEY (relationship_id);

-- Create indexes
CREATE INDEX idx_concept_concept_id  ON omopcdm.CONCEPT  (concept_id ASC);
CLUSTER omopcdm.CONCEPT  USING idx_concept_concept_id ;
CREATE INDEX idx_concept_code ON omopcdm.CONCEPT (concept_code ASC);
CREATE INDEX idx_concept_vocabluary_id ON omopcdm.CONCEPT (vocabulary_id ASC);
CREATE INDEX idx_concept_domain_id ON omopcdm.CONCEPT (domain_id ASC);
CREATE INDEX idx_concept_class_id ON omopcdm.CONCEPT (concept_class_id ASC);
CREATE INDEX idx_vocabulary_vocabulary_id  ON omopcdm.VOCABULARY  (vocabulary_id ASC);
CLUSTER omopcdm.VOCABULARY  USING idx_vocabulary_vocabulary_id ;
CREATE INDEX idx_domain_domain_id  ON omopcdm.DOMAIN  (domain_id ASC);
CLUSTER omopcdm.DOMAIN  USING idx_domain_domain_id ;
CREATE INDEX idx_concept_class_class_id  ON omopcdm.CONCEPT_CLASS  (concept_class_id ASC);
CLUSTER omopcdm.CONCEPT_CLASS  USING idx_concept_class_class_id ;
CREATE INDEX idx_concept_relationship_id_1  ON omopcdm.CONCEPT_RELATIONSHIP  (concept_id_1 ASC);
CLUSTER omopcdm.CONCEPT_RELATIONSHIP  USING idx_concept_relationship_id_1 ;
CREATE INDEX idx_concept_relationship_id_2 ON omopcdm.CONCEPT_RELATIONSHIP (concept_id_2 ASC);
CREATE INDEX idx_concept_relationship_id_3 ON omopcdm.CONCEPT_RELATIONSHIP (relationship_id ASC);
CREATE INDEX idx_relationship_rel_id  ON omopcdm.RELATIONSHIP  (relationship_id ASC);
CLUSTER omopcdm.RELATIONSHIP  USING idx_relationship_rel_id ;
CREATE INDEX idx_concept_synonym_id  ON omopcdm.CONCEPT_SYNONYM  (concept_id ASC);
CLUSTER omopcdm.CONCEPT_SYNONYM  USING idx_concept_synonym_id ;
CREATE INDEX idx_concept_ancestor_id_1  ON omopcdm.CONCEPT_ANCESTOR  (ancestor_concept_id ASC);
CLUSTER omopcdm.CONCEPT_ANCESTOR  USING idx_concept_ancestor_id_1 ;
CREATE INDEX idx_concept_ancestor_id_2 ON omopcdm.CONCEPT_ANCESTOR (descendant_concept_id ASC);
CREATE INDEX idx_drug_strength_id_1  ON omopcdm.DRUG_STRENGTH  (drug_concept_id ASC);
CLUSTER omopcdm.DRUG_STRENGTH  USING idx_drug_strength_id_1 ;
CREATE INDEX idx_drug_strength_id_2 ON omopcdm.DRUG_STRENGTH (ingredient_concept_id ASC);

-- Create foreign keys
ALTER TABLE omopcdm.CONCEPT ADD CONSTRAINT fpk_CONCEPT_domain_id FOREIGN KEY (domain_id) REFERENCES omopcdm.DOMAIN (DOMAIN_ID);
ALTER TABLE omopcdm.CONCEPT ADD CONSTRAINT fpk_CONCEPT_vocabulary_id FOREIGN KEY (vocabulary_id) REFERENCES omopcdm.VOCABULARY (VOCABULARY_ID);
ALTER TABLE omopcdm.CONCEPT ADD CONSTRAINT fpk_CONCEPT_concept_class_id FOREIGN KEY (concept_class_id) REFERENCES omopcdm.CONCEPT_CLASS (CONCEPT_CLASS_ID);
ALTER TABLE omopcdm.VOCABULARY ADD CONSTRAINT fpk_VOCABULARY_vocabulary_concept_id FOREIGN KEY (vocabulary_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DOMAIN ADD CONSTRAINT fpk_DOMAIN_domain_concept_id FOREIGN KEY (domain_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_CLASS ADD CONSTRAINT fpk_CONCEPT_CLASS_concept_class_concept_id FOREIGN KEY (concept_class_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_1 FOREIGN KEY (concept_id_1) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_2 FOREIGN KEY (concept_id_2) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_relationship_id FOREIGN KEY (relationship_id) REFERENCES omopcdm.RELATIONSHIP (RELATIONSHIP_ID);
ALTER TABLE omopcdm.RELATIONSHIP ADD CONSTRAINT fpk_RELATIONSHIP_relationship_concept_id FOREIGN KEY (relationship_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_concept_id FOREIGN KEY (concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_language_concept_id FOREIGN KEY (language_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_ancestor_concept_id FOREIGN KEY (ancestor_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_descendant_concept_id FOREIGN KEY (descendant_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_drug_concept_id FOREIGN KEY (drug_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_ingredient_concept_id FOREIGN KEY (ingredient_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_amount_unit_concept_id FOREIGN KEY (amount_unit_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_numerator_unit_concept_id FOREIGN KEY (numerator_unit_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);
ALTER TABLE omopcdm.DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_denominator_unit_concept_id FOREIGN KEY (denominator_unit_concept_id) REFERENCES omopcdm.CONCEPT (CONCEPT_ID);