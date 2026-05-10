library(DatabaseConnector)
library(SqlRender)
source('R/file.R')

connectionDetails <-  DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                 server = "dlvidhiomop1.mskcc.org/omop_raw", 
                                                                 user = "", 
                                                                 password = "", 
                                                                 port = 5432)

create_regimens(connectionDetails = connectionDetails,
               cdmDatabaseSchema = "omop_cdm_2",
               cdmResultSchema = "omop_cdm_results_2",
               writeDatabaseSchema = "onco_regimen_finder_test",
               cohortTable = "hms_cancer_cohort",
               regimenTable = "hms_cancer_regimens",
               regimenIngredientTable = "hms_cancer_regimen_ingredients",
               vocabularyTable = "regimen_voc_upd",
               drug_classification_id_input = 21601387,
               date_lag_input = 30,
               regimen_repeats = 5,
               cohortDefinitionId = 7,
               generateVocabTable = T)
