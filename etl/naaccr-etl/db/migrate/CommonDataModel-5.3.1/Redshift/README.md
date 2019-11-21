Common-Data-Model / Redshift
=================

This folder contains the SQL scripts for Amazon Redshift. 

In order to create your instance of the Common Data Model, we recommend following these steps:

1. Create an empty schema.

2. Set the search_path to that schema.

3. Execute the script `OMOP CDM redshift ddl_1.sql` to create the tables and fields.

4. Execute the script `OMOP CDM redshift ddl Oncology Module_2.sql` to create the oncology tables and fields.

5. Load the vocabulary data into the schema using COPY commands from Amazon S3. Please run these load files below. These files use the 
COPY command and Amazon S3 to load data into the vocabulary tables.
      The parts of the file must replace:
        #ETL_SCHEMA_NAME#       -> with the name of the schema created above.
        #S3_BUCKET_NAME#        -> with the directory path where the vocabulary data is stored.
        #S3_ACCESS_KEY#         -> with your S3 access key code
        #S3_SECRET_ACCESS_KEY#' -> with your S3 secret access key 
        #VOCABULARY_DELIMITER#  -> with a delimiter for example '\t' a tab delimiter. Most of the vocobulary data is "tab" delimited
   
   The files are:
   1. OMOP CDM redshift vocab load copy concept_3_1.sql
   2. OMOP CDM redshift vocab load copy concept_ancestor_3_2.sql
   3. OMOP CDM redshift vocab load copy concept_class_3_3.sql
   4. OMOP CDM redshift vocab load copy concept_relationship_3_4.sql
   5. OMOP CDM redshift vocab load copy concept_synonym_3_5.sql
   6. OMOP CDM redshift vocab load copy concept_domain_3_6.sql
   7. OMOP CDM redshift vocab load copy drug_strength_3_7.sql
   8. OMOP CDM redshift vocab load copy relationship_3_8.sql
   9. OMOP CDM redshift vocab load copy vocabulary_3_9.sql
   10. OMOP CDM redshift vocab load copy concept_numeric_3_10.sql 
   ***Note the source data file CONCEPT_NUMERIC.csv is located with this directory.
   
   
   
   
   
   
   
   
