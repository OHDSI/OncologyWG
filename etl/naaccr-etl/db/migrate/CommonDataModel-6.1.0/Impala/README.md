Common-Data-Model / Impala
=================

This folder contains the SQL scripts for Impala. 

In order to create your instantiation of the Common Data Model, we recommend following these steps:

1. Create an empty schema.

```bash
impala-shell -q 'CREATE DATABASE omop_cdm'
```

2. Execute the scripts `OMOP CDM impala ddl.txt` and `OMOP CDM Results impala ddl.txt` (you will need to convert them to sql files first) to create the tables and fields.

```bash
impala-shell -d omop_cdm -f OMOP_CDM_impala_ddl.sql
impala-shell -d omop_cdm -f OMOP_CDM_Results_impala_ddl.sql
```

3. Load your data into the schema.

a. Load the vocabulary tables.

First, download the data from
[http://www.ohdsi.org/web/athena/](http://www.ohdsi.org/web/athena/)
and unzip into a _cdmv5vocab_ directory, then run

```bash
hadoop fs -put cdmv5vocab cdmv5vocab
hadoop fs -chmod +w cdmv5vocab
impala-shell -d omop_cdm -f VocabImport/OMOP_CDM_vocabulary_load_Impala.sql --var=OMOP_VOCAB_PATH=/user/$USER/cdmv5vocab
```

b. Load the patient data.

For example, download the 1000 person sample of simulated CMS SynPUF patient data from
[http://www.ltscomputingllc.com/downloads/](http://www.ltscomputingllc.com/downloads/)
and unzip into a _synpuf_ directory, then run

```bash
hadoop fs -put synpuf synpuf
hadoop fs -chmod +w synpuf
impala-shell -d omop_cdm -f DataImport/OMOP_CDM_synpuf_load_Impala.sql --var=OMOP_SYNPUF_PATH=/user/$USER/synpuf
```
* Note that these tables are in CDM v5.2.2 format

4. Convert to Parquet format.

```bash
impala-shell -q 'CREATE DATABASE omop_cdm_parquet'
impala-shell -f OMOP_Parquet.sql
```

5. Run simple queries to sanity check.

```bash
impala-shell -d omop_cdm_parquet -q 'SELECT COUNT(1) FROM concept'
impala-shell -d omop_cdm_parquet -q 'SELECT COUNT(1) FROM person'
```