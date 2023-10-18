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

## Setting up a development database

To utilize the tools in this directory, you must have a Postgres database containing two schemas:
- **prod**: The **prod** schema contains the official ("production") OMOP Vocabulary. This vocabulary will not be changed but can be used to refresh the **dev** schema.
- **dev**: The **dev** schema begins as an exact copy of the official OMOP Vocabulary, but will be transformed using concept and concept_relationship table fragments and the tools in this directory.

These instructions provide tools for quickly setting up these two schemas with the OMOP vocabulary tables. If you are familiar with Athena and the OMOP Vocabulary, you can create these two schemas in your Postgres and stand up the latest version of the OMOP vocabulary using your own methods.

### Instructions:
#### Clone the repository

Clone the OncologyWG to your computer. If you'd prefer not to clone the entire repository, copy the vocabTools directory and its contents to your computer.

#### Download the latest OMOP Vocabulary

Download the most recent version of the OMOP Vocabulary at https://athena.ohdsi.org/vocabulary/list. Follow the instructions for importing CPT4 vocabulary into concept.csv.

Move all contents of the Athena download (i.e. the vocabulary table files: CONCEPT.csv, CONCEPT_RELATIONSHIP.csv, etc.) to the vocab directory in the vocabTools directory.

#### Configure your database connection details

Edit the config.txt file in the vocabTools directory to reflect your Postgres database connection details. If the vocabulary table files from the Athena download are in the vocab directory in the vocabTools directory, then you do not need to change the base_path variable in config.txt.

#### Create Development Vocab Environment

Once the vocabulary table files are in the vocab directory and the config.txt file reflects your database connection details, simply run the **createVocab.bat** script to create and populate the prod and dev schemas with the OMOP Vocabularies.
