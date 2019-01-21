# README

This repository contains a script to prepare and curate NAACCR data items/NAACCR data item codes to be ingested into the OMOP vocabulary tables.

* To get this application up and running locally, you will need to take the following steps:

  * Create a local PostgreSQL database.  Here are the commands to create a PostgreSQL database:
    CREATE DATABASE ohdsi_naaccr_ingestor_development;
    CREATE USER ohdsi_naaccr_ingestor_development WITH CREATEDB PASSWORD 'ohdsi_naaccr_ingestor_development';
    ALTER DATABASE ohdsi_naaccr_ingestor_development OWNER TO ohdsi_naaccr_ingestor_development;
    ALTER USER ohdsi_naaccr_ingestor_development SUPERUSER;
  * Change [database.yml](../blob/master/config/database.yml), as appropriate.
  * Migrate the database with this rake command: bundle exec rake db:migrate
  * Run this rake command: bundle exec rake ingest:do
  * Run this rake command: bundle exec rake ingest:import_curated
  * Run this rake command: bundle exec rake ingest:export_uncurated
  * Run this rake command: bundle exec rake ingest:export_naaccr_schema_icdo_mappings

* The script takes as its initial input an export of all NAACCR items from the NAACCR 'Data Standards and Data Dictionary – Query Builder' (NAACCR Query Builder) application that is available at the following location:

  http://applications.naaccr.org/querybuilder/default.aspx?Version=18

* The following 'Request fields' were exported from the NAACCR Query Builder: 'Item #', 'Item Name', 'Section', 'Codes', and 'Note' into CSV format.

* The script assumes that entries have been made in the CONCEPT table in a Treatment domain.  See [treatments.csv](../blob/master/lib/data/treatments.csv)

* The script imports into a local PostgreSQL database NAACCR items and NAACCR item codes for all NAACCR items in the input file.  It skips 'retired' fields and 'blank' codes'

* The script sets item_omop_concept_code for each NAACCR item as the NAACCR items #.  For example, '1320' for NAACCR item #1320 'RX Summ--Surgical Margins.

* For NAACCR items with a list of possible value NAACCR item codes, the script sets code_omop_concept_code for each NAACCR item code as the concatenation of NAACCR item # and NAACCR item code.   For example, here are the codes for  NAACCR item #1320 'RX Summ--Surgical Margins: '1320'.

  NAACCR Item Code Description | NAACCR Item Code Description
  ---------------------------- | ---------------------------
   No residual tumor           | 1320_0
   Residual tumor, NOS         | 1320_1
   Microscopic residual tumor  | 1320_2
   Macroscopic residual tumor  | 1320_3
   Margins not evaluable       | 1320_7
   No primary site surgery     | 1320_8

* Some NAACCR items are **site-independent** and some are **site-dependent**.
  * **Site-independent** means that the NAACCR item **is not bound** to a NAACCR schema: a list of ICDO3 site/histology combinations. The NAACCR item's list of possible values **does not** depend/alter based on the ICDO3 site/histology combination of the tumor diagnosis it describes/applies to.
  * **Site-dependent** means that the NAACCR item **is bound** to a NAACCR schema: a list of ICDO3 site/histology combinations  The NAACCR item's list of possible values possibly **does** depend/alter based on the ICDO3 site/histology of the tumor diagnosis it describes/applies to.

* The script expands the NAACCR item codes for site-dependent NAACCR items.  Currently, this expansion has only been completed for NAACCR item #1290 'RX Summ--Surg Prim Site'.  NAACCR item #1290 is the primary NAACCR item tracking first-course surgical treatment.

* To expand NAACCR item #1290, the script calls the following SEER API endpoint to retrieve a list of NAACCR surgery schemas:
  https://api.seer.cancer.gov/rest/surgery/latest/tables

 * Each schema is then passed into the following SEER API endpoint to retrieve the list of ICDO3 sites and surgery codes bound to the schema:

   https://api.seer.cancer.gov/rest/surgery/latest/table

* The script stores the list of ICD03 sites bound to each surgery schema.  For example:

 NAACCR Surgery Schema | ICDO3 Code
  ---------------------------- | ---------------------------
 Prostate                                  | C61.9
 Breast                                     | C50.0
 Breast                                     | C50.1
 Breast                                     | C50.2
 Breast                                     | C50.3
 Breast                                     | C50.4
 Breast                                     | C50.5
 Breast                                     | C50.6
 Breast                                     | C50.8
 Breast                                     | C50.9

* For NAACCR item #1290 'RX Summ--Surg Prim Site', the script sets code_omop_concept_code for each NAACCR item code as the concatenation of NAACCR item #, NAACCR schema name and NAACCR item code.   For example:

  NAACCR Item Schema | NACCR Item Code Description | NACCR Item Code Description
  ------------------ | --------------------------- | ---------------------------
  Breast             | Breast Local tumor destruction, NOS | 1290_Breast_19
  Breast             | Breast Partial mastectomy, NOS; less than total mastectomy, NOS | 1290_Breast_20
  Breast             | Breast Partial mastectomy; less than total mastectomy Partial mastectomy WITH nipple resection | 1290_Breast_21
  Prostate           | Prostate Transurethral resection (TURP), NOS | 1290_Prostate_19
  Prostate           | Prostate Local tumor excision, NOS | 1290_Prostate_20
  Prostate           | Prostate Local tumor excision Transurethral resection (TURP), NOS | 1290_Prostate_20


* For NAACCR item #1290 'RX Summ--Surg Prim Site' code, the script sets 'schema_name' for each NAACCR item code.


* Each NAACCR Item has been curated for the following fields: item_omop_domain_id, item_standard_concept, treatment_type and item_maps_to.

  * **item_omop_domain_id**: This field denotes what domain the NAACCR item should be placed into in the CONCEPT table.   For NAACCR items, this can be either 'None', 'Episode' or 'Measurement'.  'None' means that it should not be imported into the CONCEPT table.

  * **item_standard_concept**: This field denotes what value should be placed in the standard_concept column in the CONCEPT table.

  * **treatment_type**: This field denotes what type of treatment the NAACCAR items belongs to.  This should not be imported into the OMOP Vocabulary tables, but is useful for organizing the NAACCR items for ETL documentation.  This field has the following possible values:  'Chemotherapy', 'Hormone therapy', 'Immunological therapy', 'Other therapy', 'Radiation oncology AND/OR radiotherapy', 'Surgery' and 'Transplant/Endocrine thearpy'.

  * **item_maps_to**: This field contains enough information to insert 'Standard to Non-standard map (OMOP)/Non-standard to Standard map (OMOP)' entries into CONCEPT_RELATIONSHIP.  The field contains columns set to values to be able to find a standard entry in the CONCEPT table.

* Each NAACCR Item code has been curated for the following fields: code_omop_domain_id, code_standard_concept, and code_maps_to.

  * **code_omop_domain_id**: This field denotes what domain the NAACCR item code should be placed into in the CONCEPT table.  For NAACCR item codes, this can be either 'None', 'Meas Value' or 'Treatment'.  'None' means that it should not be imported into the CONCEPT table.

  * **item_standard_concept**: This field denotes what value should be placed in the standard_concept column in the CONCEPT table.

  * **code_maps_to**: This field contains enough information to insert 'Standard to Non-standard map (OMOP)/Non-standard to Standard map (OMOP)' entries into CONCEPT_RELATIONSHIP.  The field contains columns set to values to be able to find a standard entry in the CONCEPT table.

* The script contains the following commands:

  * 'ingest:do': This command imports the baseline input file, calls the SEER API, inserts NAACCR items, NAACCR item codes and NAACCR schemas.
  * "ingest:export_uncurated': This command exports the ingested NAACCR items and NAACCR item codes to [naaccr_uncurated.csv](../blob/master/lib/data_out/naaccr_uncurated.csv)
  * "ingest:import_curated': This command imports curated data file  [naaccr_curated.csv](../blob/master/lib/data/naaccr_curated.csv) to update the local PostgreSQL database with the curated fields to be saved for persistence.
  * "ingest:export_naaccr_schema_icdo_mappings': This command exports mappings from NAACCR schemas to ICDO3 codes to
   [naaccr_schema_icdo_mappings.csv](../blob/master/lib/data/naaccr_schema_icdo_mappings.csv).
