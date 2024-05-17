# Reproduction of the OHDSI Vocabulary WG pipeline
Attempting to better understand the code through reconstruction of the pipeline by Peter and Daniel

Link to original pipeline:
https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/ICDO3/load_stage.sql

Link to supporting tables:
https://drive.google.com/drive/u/2/folders/1A9PmC9T_d8zPn51RQu5Wg7zXyVRuuWN6

## under construction

Daniel to fully document process as he reproduces Odyseus and Peter's work


1. Create a database ICDO3vocab in Postgres.
2. Create schemas omopcdm, sources, snomed, and icdo3.
3. Load the vocabulary version you want to use as a reference in omopcdm.
   Use the script 'load OMOP vocabulary.sql' for this (modify where necessary).
4. Load the source files for the ICDO3 vocabulary in sources.
   Use the script 'load source files.sql' for this (modify where necessary).
5. Load SNOMED CT in snomed.
   Use the script 'load SNOMED.sql'.
6. Run 'load_stage step by step.sql' to fill the staging tables in schema icdo3.
   The parts that take the longest to run are:
   - PART 3 (~6m)
   - PART 13 (~1m)
   - PART 15 (~1.5m)
   PART 20 may lead to issues: it should run in ~30s but if it takes much longer then run it until Step 1 (in 20.5) and then run Step 1 and Step 2 separately.
   
   