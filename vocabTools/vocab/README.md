# vocab

Place the OMOP Vocabulary table files downloaded from Athena into this directory. This will enable createVocab.bat to populate the prod schema in your Postgres database.

Required tables:

CONCEPT.csv
CONCEPT_ANCESTOR.csv
CONCEPT_CLASS.csv
CONCEPT_RELATIONSHIP.csv
CONCEPT_SYNONYM.csv
DOMAIN.csv
DRUG_STRENGTH.csv
RELATIONSHIP.csv
VOCABULARY.csv