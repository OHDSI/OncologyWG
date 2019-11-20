Common-Data-Model / Oracle
=================

This folder contains the SQL scripts for Oracle. 

In order to create your instantiation of the Common Data Model, we recommend following these steps:

1. Create an empty schema.

2. Execute the script `OMOP CDM oracle v53 ddl 1.sql` to create the tables and fields.

3. Execute the script `OMOP CDM oracle oncology ext _2.sql` to create Oncology Extentsion tables and fields.

4. Load your data into the schema.
   Use OMOP CDM vocabulary load - Oracle.bat 
   
   If in Windows use the .bat file called
   OMOP CDM vocabulary load - Oracle.bat
   
   If not use
   OMOP CDM vocabulary load - Oracle.txt 
   
   This will call the Oracle Utlity SQL*Loader (sqlldr). This utilty needs files for each table called control files (ctl).
   Ensure the control files for the vocabulary tables are present. 
   OncologyWG-master\OncologyWG-master\etl\naaccr-etl\db\migrate\CommonDataModel-5.3.1\Oracle\VocabImport
   
   The list of control files are:
   =================
	CONCEPT.ctl 
	CONCEPT_ANCESTOR.ctl 
	CONCEPT_CLASS.ctl 
	CONCEPT_RELATIONSHIP.ctl 
	CONCEPT_SYNONYM.ctl
	DOMAIN.ctl 
	DRUG_STRENGTH.ctl 
	RELATIONSHIP.ctl 
	VOCABULARY.ctl 
	CONCEPT_NUMERIC.ctl 
	=================

5. Execute the script `OMOP CDM oracle indexes_3.sql` to add the minimum set of indices and primary keys we recommend.

6. Execute the script `OMOP CDM oracle oncology ext indexes_4.sql` to add oncology indices and primary keys we recommend.

7. Execute the script `OMOP CDM oracle constraints_5.sql` to add the foreign key constraints.

8. Execute the script `OMOP CDM oracle oncology ext constraints_6.sql` to add the foreign key constraints. 

Note: you could also apply the constraints and/or the indexes before loading the data, but this will slow down the insertion of the data considerably.

