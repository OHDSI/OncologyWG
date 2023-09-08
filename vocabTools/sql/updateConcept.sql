set search_path to dev;

-- DROP all foreign key constraints
ALTER TABLE vocabulary DROP CONSTRAINT fpk_vocabulary_vocabulary_concept_id;
ALTER TABLE domain DROP CONSTRAINT fpk_domain_domain_concept_id;
ALTER TABLE concept_class DROP CONSTRAINT fpk_concept_class_concept_class_concept_id;
ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_concept_id_1;
ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_concept_id_2;
ALTER TABLE relationship DROP CONSTRAINT fpk_relationship_relationship_concept_id;
ALTER TABLE concept_synonym DROP CONSTRAINT fpk_concept_synonym_concept_id;
ALTER TABLE concept_synonym DROP CONSTRAINT fpk_concept_synonym_language_concept_id;
ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_ancestor_concept_id;
ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_descendant_concept_id;
ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_source_concept_id;
ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_target_concept_id;
ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_drug_concept_id;
ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_ingredient_concept_id;
ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_amount_unit_concept_id;
ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_numerator_unit_concept_id;
ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_denominator_unit_concept_id;
ALTER TABLE cohort_definition DROP CONSTRAINT fpk_cohort_definition_definition_type_concept_id;
ALTER TABLE cohort_definition DROP CONSTRAINT fpk_cohort_definition_subject_concept_id;


--  Perform the update
DELETE FROM concept WHERE concept_id IN (SELECT concept_id FROM temp_concept_data);

INSERT INTO concept SELECT * FROM temp_concept_data;


-- Recreate foreign key constraints for each referencing table

-- Add foreign key constraints back for vocabulary
ALTER TABLE vocabulary
ADD CONSTRAINT fpk_vocabulary_vocabulary_concept_id
FOREIGN KEY (vocabulary_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for domain
ALTER TABLE domain
ADD CONSTRAINT fpk_domain_domain_concept_id
FOREIGN KEY (domain_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for concept_class
ALTER TABLE concept_class
ADD CONSTRAINT fpk_concept_class_concept_class_concept_id
FOREIGN KEY (concept_class_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for concept_relationship
ALTER TABLE concept_relationship
ADD CONSTRAINT fpk_concept_relationship_concept_id_1
FOREIGN KEY (concept_id_1)
REFERENCES concept (concept_id);

ALTER TABLE concept_relationship
ADD CONSTRAINT fpk_concept_relationship_concept_id_2
FOREIGN KEY (concept_id_2)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for relationship
ALTER TABLE relationship
ADD CONSTRAINT fpk_relationship_relationship_concept_id
FOREIGN KEY (relationship_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for concept_synonym
ALTER TABLE concept_synonym
ADD CONSTRAINT fpk_concept_synonym_concept_id
FOREIGN KEY (concept_id)
REFERENCES concept (concept_id);

ALTER TABLE concept_synonym
ADD CONSTRAINT fpk_concept_synonym_language_concept_id
FOREIGN KEY (language_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for concept_ancestor
ALTER TABLE concept_ancestor
ADD CONSTRAINT fpk_concept_ancestor_ancestor_concept_id
FOREIGN KEY (ancestor_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE concept_ancestor
ADD CONSTRAINT fpk_concept_ancestor_descendant_concept_id
FOREIGN KEY (descendant_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for source_to_concept_map
ALTER TABLE source_to_concept_map
ADD CONSTRAINT fpk_source_to_concept_map_source_concept_id
FOREIGN KEY (source_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE source_to_concept_map
ADD CONSTRAINT fpk_source_to_concept_map_target_concept_id
FOREIGN KEY (target_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for drug_strength
ALTER TABLE drug_strength
ADD CONSTRAINT fpk_drug_strength_drug_concept_id
FOREIGN KEY (drug_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE drug_strength
ADD CONSTRAINT fpk_drug_strength_ingredient_concept_id
FOREIGN KEY (ingredient_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE drug_strength
ADD CONSTRAINT fpk_drug_strength_amount_unit_concept_id
FOREIGN KEY (amount_unit_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE drug_strength
ADD CONSTRAINT fpk_drug_strength_numerator_unit_concept_id
FOREIGN KEY (numerator_unit_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE drug_strength
ADD CONSTRAINT fpk_drug_strength_denominator_unit_concept_id
FOREIGN KEY (denominator_unit_concept_id)
REFERENCES concept (concept_id);

-- Add foreign key constraints back for cohort_definition
ALTER TABLE cohort_definition
ADD CONSTRAINT fpk_cohort_definition_definition_type_concept_id
FOREIGN KEY (definition_type_concept_id)
REFERENCES concept (concept_id);

ALTER TABLE cohort_definition
ADD CONSTRAINT fpk_cohort_definition_subject_concept_id
FOREIGN KEY (subject_concept_id)
REFERENCES concept (concept_id);
