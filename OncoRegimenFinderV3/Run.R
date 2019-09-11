library(DatabaseConnector)
library(SqlRender)
source('R/file.R')

connectionDetails <-  DatabaseConnector::createConnectionDetails(dbms = "redshift", 
                                                                 server = "", 
                                                                 user = "", 
                                                                 password = "", 
                                                                 port = 5439)

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
               generateVocabTable = F)
