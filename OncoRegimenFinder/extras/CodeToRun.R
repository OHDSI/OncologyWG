devtools::install_github("OHDSI/DatabaseConnector")
library(DatabaseConnector)
devtools::install_github("OHDSI/SqlRender")
library(SqlRender)
devtools::install_github("OHDSI/OncologyWG", subdir = "OncoRegimenFinder")
library(OncoRegimenFinder)

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  server = paste0(Sys.getenv("ONCO_SERVER"),"/prod_oncoemr"),
  user = Sys.getenv("REDSHIFT_USER"),
  password = Sys.getenv("REDSHIFT_PASSWORD"),
  port = "5439")

cohortDatabaseSchema <- "study_reference"
cdmDatabaseSchema <- "full_201909_omop_v5"
vocabularyTable <- "regimen_voc_upd"

cohortTable <- "as_cancer_cohort_test"
regimenTable <- "as_cancer_regimens_test"
regimenIngredientTable <- "as_cancer_regimen_ingredients_test"


OncoRegimenFinder::create_regimens(connectionDetails = connectionDetails,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   writeDatabaseSchema = cohortDatabaseSchema,
                                   cohortTable = cohortTable,
                                   regimenTable = regimenTable,
                                   regimenIngredientTable = regimenIngredientTable,
                                   vocabularyTable = vocabularyTable,
                                   drug_classification_id_input = 21601387,
                                   date_lag_input = 30,
                                   regimen_repeats = 5,
                                   generateVocabTable = F)
