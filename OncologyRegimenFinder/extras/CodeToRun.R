# *******************************************************
# -----------------INSTRUCTIONS -------------------------
# *******************************************************
#
#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------
# This CodeToRun.R is provided as an example of how to run this package.
# Below you will find 2 sections: the 1st is for installing the dependencies
# required to run the study and the 2nd for running the package.
#
# The code below makes use of R environment variables (denoted by "Sys.getenv(<setting>)") to
# allow for protection of sensitive information. If you'd like to use R environment variables stored
# in an external file, this can be done by creating an .Renviron file in the root of the folder
# where you have cloned this code. For more information on setting environment variables please refer to:
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRenviron.html
#
#
# Below is an example .Renviron file's contents: (please remove)
# the "#" below as these too are interprted as comments in the .Renviron file:
#
#    DBMS = "postgresql"
#    DB_SERVER = "database.server.com"
#    DB_PORT = 5432
#    DB_USER = "database_user_name_goes_here"
#    DB_PASSWORD = "your_secret_password"
#    FFTEMP_DIR = "E:/fftemp"
#    CDM_SCHEMA = "your_cdm_schema"
#    COHORT_SCHEMA = "public"  # or other schema to write intermediate results to
#    PATH_TO_DRIVER = "/path/to/jdbc_driver"
#
# The following describes the settings
#    DBMS, DB_SERVER, DB_PORT, DB_USER, DB_PASSWORD := These are the details used to connect
#    to your database server. For more information on how these are set, please refer to:
#    http://ohdsi.github.io/DatabaseConnector/
#
#    FFTEMP_DIR = A directory where temporary files used by the FF package are stored while running.
#
#
# Once you have established an .Renviron file, you must restart your R session for R to pick up these new
# variables.
#
# In section 2 below, you will also need to update the code to use your site specific values. Please scroll
# down for specific instructions.
#-----------------------------------------------------------------------------------------------
#
#
# *******************************************************
# SECTION 1: Install the package and its dependencies (not needed if already done) -------------
# *******************************************************
remotes::install_github("OHDSI/DatabaseConnector")
library(DatabaseConnector)
remotes::install_github("OHDSI/SqlRender")
library(SqlRender)
remotes::install_github("A1exanderAlexeyuk/OncologyRegimenFinder")
library(OncologyRegimenFinder)


# Details for connecting to the server:
dbms = Sys.getenv("DBMS") # avalible only 3: redshift, bigquery, postgresql
user <- if (Sys.getenv("DB_USER") == "") NULL else Sys.getenv("DB_USER")
password <- if (Sys.getenv("DB_PASSWORD") == "") NULL else Sys.getenv("DB_PASSWORD")
#password <- Sys.getenv("DB_PASSWORD")
server = Sys.getenv("DB_SERVER")
port = Sys.getenv("DB_PORT")
extraSettings <- if (Sys.getenv("DB_EXTRA_SETTINGS") == "") NULL else Sys.getenv("DB_EXTRA_SETTINGS")
pathToDriver <- if (Sys.getenv("PATH_TO_DRIVER") == "") NULL else Sys.getenv("PATH_TO_DRIVER")
connectionString <- if (Sys.getenv("CONNECTION_STRING") == "") NULL else Sys.getenv("CONNECTION_STRING")

connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    server = server,
    user = user,
    password = password,
    port = port,
    pathToDriver = pathToDriver)

writeDatabaseSchema <- "study_reference"
cdmDatabaseSchema <- "full_201909_omop_v5"
vocabularyTable <- "regimen_voc_upd"
cohortTable <- "cancer_cohort"
regimenTable <- "cancer_regimens"
regimenIngredientTable <- "regimen_ingredient_table"
episodeTypeConceptId <- 32545
episodeEventTableConceptId <- 1147094
useHemoncToPullDrugs = TRUE # if TRUE drug concept_ids will be collected from HemOnc, otherwise from internal csv
writeToEpisodeTable = TRUE # if TRUE delete where episode_type_concept_id = episodeTypeConceptId  (old records) and insert updated info
writeToEpisodeEventTable = TRUE #if TRUE delete where episode_event_table_concept_id = episodeEventTableConceptId (old records) and insert       #updated info
OncologyRegimenFinder::createRegimens(
    connectionDetails,
    cdmDatabaseSchema,
    writeDatabaseSchema,
    cohortTable,
    rawEventTable,
    regimenTable,
    regimenIngredientTable,
    vocabularyTable,
    cancerConceptId = 4115276,
    dateLagInput = 30,
    generateVocabTable = T,
    generateRawEvents = FALSE,
    keepSteroids = FALSE,
    useHemoncToPullDrugs,
    episodeTypeConceptId,
    episodeEventTableConceptId,
    writeToEpisodeTable,
    writeToEpisodeEventTable
)
