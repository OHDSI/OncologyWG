# Make sure to install all dependencies (not needed if already done):
install.packages("SqlRender")
install.packages("DatabaseConnector")
install.packages("ggplot2")
install.packages("ParallelLogger")
install.packages("readr")
install.packages("tibble")
install.packages("dplyr")
install.packages("RJSONIO")
install.packages("devtools")
devtools::install_github("FeatureExtraction")
devtools::install_github("ROhdsiWebApi")
devtools::install_github("CohortDiagnostics")


# Load the package
library(ohdsiBCnew)

# Optional: specify where the temporary files will be created:
options(andromedaTempFolder = "s:/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()


# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = Sys.getenv("PDW_SERVER"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("PDW_PORT"))

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Details specific to the database:
outputFolder <- paste0(getwd(),"/results")
cdmDatabaseSchema <- "cdm_ibm_mdcd_v1023.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_skeleton_mdcd"
databaseId <- "MDCD"
databaseName <- "Truven Health MarketScan® Multi-State Medicaid Database"
databaseDescription <- "Truven Health MarketScan® Multi-State Medicaid Database (MDCD) adjudicated US health insurance claims for Medicaid enrollees from multiple states and includes hospital discharge diagnoses, outpatient diagnoses and procedures, and outpatient pharmacy claims as well as ethnicity and Medicare eligibility. Members maintain their same identifier even if they leave the system for a brief period however the dataset lacks lab data. [For further information link to RWE site for Truven MDCD."

# Use this to run the cohorttDiagnostics. The results will be stored in the diagnosticsExport subfolder of the outputFolder. This can be shared between sites.
runCohortDiagnostics(connectionDetails = connectionDetails,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     cohortDatabaseSchema = cohortDatabaseSchema,
                     cohortTable = cohortTable,
                     oracleTempSchema = oracleTempSchema,
                     outputFolder = outputFolder,
                     databaseId = databaseId,
                     databaseName = databaseName,
                     databaseDescription = databaseDescription,
                     createCohorts = TRUE,
                     runInclusionStatistics = TRUE,
                     runIncludedSourceConcepts = TRUE,
                     runOrphanConcepts = TRUE,
                     runTimeDistributions = TRUE,
                     runBreakdownIndexEvents = TRUE,
                     runIncidenceRates = TRUE,
                     runCohortOverlap = TRUE,
                     runCohortCharacterization = TRUE,
                     minCellCount = 5)

# To view the results:
# Optional: if there are results zip files from multiple sites in a folder, this merges them, which will speed up starting the viewer:
CohortDiagnostics::preMergeDiagnosticsFiles(file.path(outputFolder, "diagnosticsExport"))

# Use this to view the results. Multiple zip files can be in the same folder. If the files were pre-merged, this is automatically detected: 
CohortDiagnostics::launchDiagnosticsExplorer(file.path(outputFolder, "diagnosticsExport"))


# To explore a specific cohort in the local database, viewing patient profiles:
CohortDiagnostics::launchCohortExplorer(connectionDetails = connectionDetails,
                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                        cohortDatabaseSchema = cohortDatabaseSchema,
                                        cohortTable = cohortTable,
                                        cohortId = 123)
# Where 123 is the ID of the cohort you wish to inspect.


###########BC Outcomes #####################
regimenIngredientsTable <- "hms_cancer_regimen_ingredients"
deathTable <- "death"
count_mask <- 10

library(tidyverse)
#install.packages("lubridate")
library(lubridate)
#install.packages("toOrdinal")
#library(toOrdinal)
#install.packages("RColorBrewer")
library(RColorBrewer)
#install.packages("survival")
library(survival)

#### Run
source("extras/regimen_stats.R")
outputFolder <- paste0(getwd(),"/results/Additional")

write.csv(population_summary, file.path(outputFolder, "population_summary.csv"))
write.csv(stats_by_line, file.path(outputFolder, "lines_of_treatment.csv"))
write.csv(regimens_by_treatment_line, file.path(outputFolder, "regimens_by_line.csv"))
write.csv(yearly_regimens_by_treatment_line, file.path(outputFolder, "yearly_regimens_by_line.csv"))
write.csv(km_outputs$OS, file.path(outputFolder, "os_km.csv"))
write.csv(km_outputs$TTNT, file.path(outputFolder, "ttnt_km.csv"))
write.csv(km_outputs$TTD, file.path(outputFolder, "ttd.csv"))

write.csv(km_outputs$TFI, file.path(outputFolder, "tfi_km.csv"))
write.csv(ages, file.path(outputFolder, "age.csv"))
