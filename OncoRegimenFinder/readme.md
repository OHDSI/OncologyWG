OncoRegimenFinder
==============================

  This package identifies oncology regimens. Firstly, it identifies all patients who have been exposed with an Antineoplastic Agent (ATC code). Then it collapses the antineoplastic agents into regimens when there is a date difference less that @date_lag_input(30days is used as standard).

Requirements
============

  - A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: Amazon RedShift.
- R version 3.5.0 or newer

See [this video](https://youtu.be/K9_0s2Rchbo) for instructions on how to set up the R environment on Windows.

How to run
==========
  1. In `R`, use the following code to install the dependencies:

  ```r
install.packages("devtools")
install.packages("tidyverse")
library(devtools)
library(tidyverse)
install_package("rJava")
install_package("SqlRender")
install_package("DatabaseConnector")
```

If you experience problems on Windows where rJava can't find Java, one solution may be to add `args = "--no-multiarch"` to each `install_github` call, for example:

	```r
	install_github("ohdsi/SqlRender", args = "--no-multiarch")
	```

	Alternatively, ensure that you have installed both 32-bit and 64-bit JDK versions, as mentioned in the [video tutorial](https://youtu.be/K9_0s2Rchbo).



3. Once installed, you can execute the study by modifying and using the following code:

	```r


	# Details for connecting to the server:
	# See ?DatabaseConnector::createConnectionDetails for help
	connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
									server = "some.server.com/ohdsi",
									user = "joe",
									password = "secret")

	# The name of the database schema where the CDM data can be found:
	cdmDatabaseSchema <- "cdm_synpuf"

	# The name of the database schema and table where the study-specific cohorts will be instantiated:
	cohortDatabaseSchema <- "scratch.dbo"
	cohortTable <- "my_study_cohorts"

	#The name of the table that will contain the regimens.
	regimenTable <- "cancer_regimens"

	#The name of the table that will contatin all the information needed in order to generate the episode tables
	regimenIngredientTable <- "hms_cancer_regimen_ingredients"

	#The name of the table that will contain a re-formatted version of the HemOnc vocabulary
	vocabularyTable <- "regimen_voc_upd"

	#ATC classification code set
	drug_classification_id_input <- 21601387

	#The days between individual ingredients that will be collapsed into a regimen
	date_lag_input <- 30

	#Generates a loop that helps identify regimens. At this step, 5 would be sufficient.
	regimen_repeats <- 5

	#When you run it for the first time set it TRUE. When you re run the package set it as FALSE.
	generateVocabTable = F

	Example:

      create_regimens(connectionDetails = connectionDetails,
                   cdmDatabaseSchema = "full_201904_omop_v5",
                   writeDatabaseSchema = "study_reference",
                   cohortTable = "hms_cancer_cohort",
                   regimenTable = "hms_cancer_regimens",
                   regimenIngredientTable = "hms_cancer_regimen_ingredients",
                   vocabularyTable = "regimen_voc_upd",
                   drug_classification_id_input = 21601387,
                   date_lag_input = 30,
                   regimen_repeats = 5,
                   generateVocabTable = T)

	```

4. The output of the package can be found in the regimenIngredientTable. And can be used to populate the episode table. Example:

	```SQL
	-- -------------------------------------------------------------------
	-- Treatment Episode of Regimen
	-- -------------------------------------------------------------------

    EXECUTE PREP_INSERT_LOG
        ( 2                         -- Step Number
        , 'PR - INS: episode'       -- Step Name
        , 'PROCESS - START'         -- Status
        );

    COMMIT;

    INSERT INTO #EXT_SCHEMA_NAME#.episode_f
    (
        person_id,
        episode_concept_id,
        episode_start_datetime,
        episode_end_datetime,
        episode_parent_id,
        episode_number,
        episode_object_concept_id,
        episode_type_concept_id,
        episode_source_value,
        episode_source_concept_id,
        identity_id
    )
    SELECT
        src.person_id                           AS person_id,
        32531                                   AS episode_concept_id,          -- 'Treatment Regimen'
        src.regimen_start_date                  AS episode_start_datetime,
        src.regimen_end_date                    AS episode_end_datetime,
        NULL                                    AS episode_parent_id,
        NULL::integer                           AS episode_number,
        COALESCE(src.hemonc_concept_id, 0)      AS episode_object_concept_id,
        32545                                   AS episode_type_concept_id,     -- 'Episode algorithmically derived from EHR'
        NULL                                    AS episode_source_value,
        0                                       AS episode_source_concept_id,
        NULL                                    AS identity_id
    FROM
        #EXT_SCHEMA_NAME#.cancer_regimen_ingredients src
    GROUP BY
        src.person_id,
        src.regimen,
        src.hemonc_concept_id,
        src.regimen_start_date,
        src.regimen_end_date
    ;

    COMMIT;

	-- -------------------------------------------------------------------
	-- Treatment Episode Events
	-- -------------------------------------------------------------------

    EXECUTE PREP_INSERT_LOG
        ( 2                             -- Step Number
        , 'PR - INS: episode_event'     -- Step Name
        , 'PROCESS - START'             -- Status
        );

    COMMIT;

    INSERT INTO #EXT_SCHEMA_NAME#.episode_event_f
    (
        episode_id,
        event_id,
        event_table_concept_id
    )
    SELECT
        ep.episode_id                   AS episode_id,
        dr.drug_exposure_id             AS event_id,
        1147094                         AS event_table_concept_id   -- 'drug_exposure.drug_exposure_id'
    FROM
        #EXT_SCHEMA_NAME#.cancer_regimen_ingredients src
    INNER JOIN
        #EXT_SCHEMA_NAME#.episode_f ep
            ON  ep.person_id = src.person_id
            AND ep.episode_object_concept_id = COALESCE(src.hemonc_concept_id, 0)
            AND ep.episode_start_datetime = src.regimen_start_date
            AND ep.episode_end_datetime = src.regimen_end_date
            AND ep.episode_concept_id = 32531           -- 'Treatment Regimen'
    INNER JOIN
        #ETL_SCHEMA_NAME#.drug_era_f de
            ON de.drug_era_id = src.drug_era_id
    INNER JOIN
        #ETL_SCHEMA_NAME#.drug_strength_f ds
            ON  ds.ingredient_concept_id = de.drug_concept_id
            AND ds.invalid_reason IS NULL
    INNER JOIN
        #ETL_SCHEMA_NAME#.drug_exposure_f dr
            ON dr.drug_concept_id = ds.drug_concept_id
            AND dr.person_id = src.person_id
            AND dr.drug_exposure_start_date BETWEEN src.regimen_start_date AND src.regimen_end_date
    ;

    COMMIT;
	```
