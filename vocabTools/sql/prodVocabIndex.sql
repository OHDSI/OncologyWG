set search_path to prod;

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