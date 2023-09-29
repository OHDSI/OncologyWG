-- I want to create a clone of an existing schema (and all tables and all of their data) in postgres

DROP SCHEMA dev CASCADE;

CREATE SCHEMA dev;

-- Clone the cohort table
CREATE TABLE dev.cohort AS
SELECT * FROM prod.cohort;

-- Clone the cohort_definition table
CREATE TABLE dev.cohort_definition AS
SELECT * FROM prod.cohort_definition;

-- Clone the concept table
CREATE TABLE dev.concept AS
SELECT * FROM prod.concept;

-- Clone the concept_ancestor table
CREATE TABLE dev.concept_ancestor AS
SELECT * FROM prod.concept_ancestor;

-- Clone the concept_class table
CREATE TABLE dev.concept_class AS
SELECT * FROM prod.concept_class;

-- Clone the concept_relationship table
CREATE TABLE dev.concept_relationship AS
SELECT * FROM prod.concept_relationship;

-- Clone the concept_synonym table
CREATE TABLE dev.concept_synonym AS
SELECT * FROM prod.concept_synonym;

-- Clone the domain table
CREATE TABLE dev.domain AS
SELECT * FROM prod.domain;

-- Clone the drug_strength table
CREATE TABLE dev.drug_strength AS
SELECT * FROM prod.drug_strength;

-- Clone the relationship table
CREATE TABLE dev.relationship AS
SELECT * FROM prod.relationship;

-- Clone the source_to_concept_map table
CREATE TABLE dev.source_to_concept_map AS
SELECT * FROM prod.source_to_concept_map;

-- Clone the vocabulary table
CREATE TABLE dev.vocabulary AS
SELECT * FROM prod.vocabulary;

set search_path to dev;

-- PKs

ALTER TABLE CONCEPT ADD CONSTRAINT xpk_CONCEPT PRIMARY KEY (concept_id);
ALTER TABLE VOCABULARY ADD CONSTRAINT xpk_VOCABULARY PRIMARY KEY (vocabulary_id);
ALTER TABLE DOMAIN ADD CONSTRAINT xpk_DOMAIN PRIMARY KEY (domain_id);
ALTER TABLE CONCEPT_CLASS ADD CONSTRAINT xpk_CONCEPT_CLASS PRIMARY KEY (concept_class_id);
ALTER TABLE RELATIONSHIP ADD CONSTRAINT xpk_RELATIONSHIP PRIMARY KEY (relationship_id);

-- FKs

ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_domain_id FOREIGN KEY (domain_id) REFERENCES DOMAIN (DOMAIN_ID);
ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_vocabulary_id FOREIGN KEY (vocabulary_id) REFERENCES VOCABULARY (VOCABULARY_ID);
ALTER TABLE CONCEPT ADD CONSTRAINT fpk_CONCEPT_concept_class_id FOREIGN KEY (concept_class_id) REFERENCES CONCEPT_CLASS (CONCEPT_CLASS_ID);
ALTER TABLE VOCABULARY ADD CONSTRAINT fpk_VOCABULARY_vocabulary_concept_id FOREIGN KEY (vocabulary_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DOMAIN ADD CONSTRAINT fpk_DOMAIN_domain_concept_id FOREIGN KEY (domain_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_CLASS ADD CONSTRAINT fpk_CONCEPT_CLASS_concept_class_concept_id FOREIGN KEY (concept_class_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_1 FOREIGN KEY (concept_id_1) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_concept_id_2 FOREIGN KEY (concept_id_2) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_RELATIONSHIP ADD CONSTRAINT fpk_CONCEPT_RELATIONSHIP_relationship_id FOREIGN KEY (relationship_id) REFERENCES RELATIONSHIP (RELATIONSHIP_ID);
ALTER TABLE RELATIONSHIP ADD CONSTRAINT fpk_RELATIONSHIP_relationship_concept_id FOREIGN KEY (relationship_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_concept_id FOREIGN KEY (concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_SYNONYM ADD CONSTRAINT fpk_CONCEPT_SYNONYM_language_concept_id FOREIGN KEY (language_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_ancestor_concept_id FOREIGN KEY (ancestor_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE CONCEPT_ANCESTOR ADD CONSTRAINT fpk_CONCEPT_ANCESTOR_descendant_concept_id FOREIGN KEY (descendant_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_source_concept_id FOREIGN KEY (source_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_target_concept_id FOREIGN KEY (target_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE SOURCE_TO_CONCEPT_MAP ADD CONSTRAINT fpk_SOURCE_TO_CONCEPT_MAP_target_vocabulary_id FOREIGN KEY (target_vocabulary_id) REFERENCES VOCABULARY (VOCABULARY_ID);
ALTER TABLE DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_drug_concept_id FOREIGN KEY (drug_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_ingredient_concept_id FOREIGN KEY (ingredient_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_amount_unit_concept_id FOREIGN KEY (amount_unit_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_numerator_unit_concept_id FOREIGN KEY (numerator_unit_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE DRUG_STRENGTH ADD CONSTRAINT fpk_DRUG_STRENGTH_denominator_unit_concept_id FOREIGN KEY (denominator_unit_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE COHORT_DEFINITION ADD CONSTRAINT fpk_COHORT_DEFINITION_definition_type_concept_id FOREIGN KEY (definition_type_concept_id) REFERENCES CONCEPT (CONCEPT_ID);
ALTER TABLE COHORT_DEFINITION ADD CONSTRAINT fpk_COHORT_DEFINITION_subject_concept_id FOREIGN KEY (subject_concept_id) REFERENCES CONCEPT (CONCEPT_ID);

-- Indexes

CREATE INDEX idx_concept_concept_id  ON concept  (concept_id ASC);
CLUSTER concept  USING idx_concept_concept_id ;
CREATE INDEX idx_concept_code ON concept (concept_code ASC);
CREATE INDEX idx_concept_vocabluary_id ON concept (vocabulary_id ASC);
CREATE INDEX idx_concept_domain_id ON concept (domain_id ASC);
CREATE INDEX idx_concept_class_id ON concept (concept_class_id ASC);
CREATE INDEX idx_vocabulary_vocabulary_id  ON vocabulary  (vocabulary_id ASC);
CLUSTER vocabulary  USING idx_vocabulary_vocabulary_id ;
CREATE INDEX idx_domain_domain_id  ON domain  (domain_id ASC);
CLUSTER domain  USING idx_domain_domain_id ;
CREATE INDEX idx_concept_class_class_id  ON concept_class  (concept_class_id ASC);
CLUSTER concept_class  USING idx_concept_class_class_id ;
CREATE INDEX idx_concept_relationship_id_1  ON concept_relationship  (concept_id_1 ASC);
CLUSTER concept_relationship  USING idx_concept_relationship_id_1 ;
CREATE INDEX idx_concept_relationship_id_2 ON concept_relationship (concept_id_2 ASC);
CREATE INDEX idx_concept_relationship_id_3 ON concept_relationship (relationship_id ASC);
CREATE INDEX idx_relationship_rel_id  ON relationship  (relationship_id ASC);
CLUSTER relationship  USING idx_relationship_rel_id ;
CREATE INDEX idx_concept_synonym_id  ON concept_synonym  (concept_id ASC);
CLUSTER concept_synonym  USING idx_concept_synonym_id ;
CREATE INDEX idx_concept_ancestor_id_1  ON concept_ancestor  (ancestor_concept_id ASC);
CLUSTER concept_ancestor  USING idx_concept_ancestor_id_1 ;
CREATE INDEX idx_concept_ancestor_id_2 ON concept_ancestor (descendant_concept_id ASC);
CREATE INDEX idx_source_to_concept_map_3  ON source_to_concept_map  (target_concept_id ASC);
CLUSTER source_to_concept_map  USING idx_source_to_concept_map_3 ;
CREATE INDEX idx_source_to_concept_map_1 ON source_to_concept_map (source_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_2 ON source_to_concept_map (target_vocabulary_id ASC);
CREATE INDEX idx_source_to_concept_map_c ON source_to_concept_map (source_code ASC);
CREATE INDEX idx_drug_strength_id_1  ON drug_strength  (drug_concept_id ASC);
CLUSTER drug_strength  USING idx_drug_strength_id_1 ;
CREATE INDEX idx_drug_strength_id_2 ON drug_strength (ingredient_concept_id ASC);