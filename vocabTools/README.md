# Tools used to assist with developing OMOP Vocabulary

## Overview
Tools to quickly set up an environment for making local edits to the OMOP Vocabularies (concept and concept_relationship tables), generating derived tables (concept_ancestor), validating the vocabulary changes, and outputting the table delta in a sharable format

## Functions
- TODO Initial set up (requires user to manually download vocab files from Athena, extract CPT concepts, and put all files in vocab folder)
  - Stand up an empty postgres database in a docker container (optional)
  - Create a prod and dev schema
  - Execute vocab table DDLs, create PK/FKs, load Vocab data from Athena files, create indexes
- Full refresh (drop dev schema, recreate from prod schema)
- updateConcept (takes one or more concept_ tables and updates the dev.concept table)
  - Checks if there are duplicate concepts
  - Removes FK constraints
  - Updates concept (deletes existing concepts, adds new ones)
  - Adds back FK constraints
- updateConceptRelationship (takes one or more concept_relationship_ tables and updates the dev.concept_relationship table)
- TODO updateConceptAncestor (updates the concept_ancestor table using the script from Vocab WG)
- getConceptDiffs (display rows in dev.concept that differ from prod.concept)
- getConceptRelationshipDiffs (display rows in dev.concept_relationship that differ from prod.concept_relationship)
- getConceptAncestorDiffs (display rows in dev.concept_ancestor that differ from prod.concept_ancestor)
- TODO Quality checks (generic_update) from vocab WG scripts

-- TODO set up config file for database info
