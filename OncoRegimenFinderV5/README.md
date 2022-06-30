OncologyRegimenFinder
====================
This is a package specific for the OMOP СDM databases, which makes it possible to determine the regimens of  cancer therapy.

Introduction
============

Filtration of medicinal ingredients was made by searching for concepts from the HemOnc release 2021 and having a relationship_id: 
Has AB-drug cjgt Rx, Has cytotox chemo Rx, Has endocrine tx Rx, Has immunotherapy Rx, Has pept-drg cjg Rx, Has radiocjgt Rx, Has radiotherapy Rx, Has targeted tx Rx, Has antineopl Rx, Has immunosuppr Rx.
Thus, over 10.000 standard RxNorm concepts are included.

The key part of the package is located in the inst folder, where sql files are stored that can be used for 3 sql dialects: postgresql, bigquery, redshift.

SQL files are wrapped in R functions. The main function, the only one that is exported is createRegimens, which has a side effect of creating a `regimenIngredientTable` in `writeDatabaseSchema`.
R files createFunctions and Utilits are a set of helper functions for createRegimens.

The extras folder contains the CodeToRun.R file, which contains a set of requirements and necessary arguments for calling the key function of the package.

Overview
========
Algorithm for the formation of `regimenIngredientTable`.
CohortBuild.sql
At the first stage, all use cases of patients receiving anticancer therapy (including all children of standard RxNorm concepts) are collected using the DrugEra table.
RegimenCalculation.sql
Further, several successive data transformations take place to obtain ingredients grouped by dates, which will subsequently be combined into modes.
Add_groups temporary table includes grouped data with highlighting the minimum start date of treatment and left join according to the start of therapy “r2.ingredient_start_date <= (r1.ingredient_start_date) and
  r2.ingredient_start_date> = (r1.ingredient_start_date - 30)”
Thus, a table is obtained grouped according to the beginning of therapy with the capture of the 30-day interval.
Next, a temporary regimens table is formed, where ingredient (1) is marked, the date of which corresponds to the minimum value in the group
Then the regimens_to_keep table is formed, which selects records with label 1; then there is a union of the original table and regimens _to_keep, followed by the formation of regimenTable.
RawEvents.sql
Optional script that generates a table using interests and oncology of interest for possible further analysis
RegimenFormat.sql
Then the ingredients are aggregated into one cell according to the same therapy start date and number.
RegimenVocabulary.sql
An optional script, the task of which is to find a match between the found mode and the mode in HemOnc selection

# *******************************************************
# -----------------INSTRUCTIONS -------------------------
# *******************************************************

## How to Run the Study
1. In `R`, you will build an `.Renviron` file. An `.Renviron` is an R environment file that sets variables you will be using in your code. It is encouraged to store these inside your environment so that you can protect sensitive information. Below are brief instructions on how to do this:

````
# The code below makes use of R environment variables (denoted by "Sys.getenv(<setting>)") to 
# allow for protection of sensitive information. If you'd like to use R environment variables stored
# in an external file, this can be done by creating an .Renviron file in the root of the folder
# where you have cloned this code. For more information on setting environment variables please refer to: 
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRenviron.html
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
#    USE_SUBSET = FALSE
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
#    USE_SUBSET = TRUE/FALSE. When set to TRUE, this will allow for runnning this package with a 
#    subset of the cohorts/features. This is used for testing. PLEASE NOTE: This is only enabled
#    by setting this environment variable.
#
# Once you have established an .Renviron file, you must restart your R session for R to pick up these new
# variables. 
````

*Note: If you are using the `DatabaseConnector` package for the first time, then you may also need to download the JDBC drivers to your database. See the [package documentation](https://ohdsi.github.io/DatabaseConnector/reference/jdbcDrivers.html), you can do this with a command like `DatabaseConnector::downloadJdbcDrivers(dbms="redshift", pathToDriver="/my-home-folder/jdbcdrivers")`.*

*Note: if you run into 403 errors from Github URLs when installing the package, you may have exceeded your Github API rate limit. If you have a Github account, then you can create a personal access token (PAT) using the link https://github.com/settings/tokens/new?scopes=repo,gist&description=R:GITHUB_PAT, and add that to your local environment, for example using `credentials::set_github_pat()` (install the package with `install.packages("credentials")` if you don't have it). The counter should also reset after an hour, so alternatively you can wait for that to happen.*

3. Great work! Now you have set-up your environment and installed the library that will run the package. You can use the following `R` script to load in your library and configure your environment connection details:

```
devtools::install_github("OHDSI/DatabaseConnector")
library(DatabaseConnector)
devtools::install_github("OHDSI/SqlRender")
library(SqlRender)
devtools::install_github("A1exanderAlexeyuk/OncologyRegimenFinder")
library(OncologyRegimenFinder)


# Details for connecting to the server:
dbms = Sys.getenv("DBMS")
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


OncologyRegimenFinder::createRegimens(connectionDetails,
                                    cdmDatabaseSchema,
                                    writeDatabaseSchema,
                                    cohortTable,
                                    rawEventTable,
                                    regimenTable,
                                    regimenIngredientTable,
                                    vocabularyTable,
                                    cancerConceptId = 4115276,
                                    dateLagInput = 30,
                                    generateVocabTable = FALSE,
                                    generateRawEvents = FALSE
                                    )
