Example Package
===============

This study package demonstrates how to currently use CohortDiagnostics in a package. The package only contains code to run StudyDiagnostics.

To modify the package to include the cohorts of interest, take these steps:

1. Copy/download the *examplePackage* folder. For example, download the Zip file [here](https://github.com/OHDSI/CohortDiagnostics/archive/master.zip), open it, and locate the *examplePackage* folder and extract it.

2. Change the package name as needed. Most importantly:
    - Change the `Package:` field in the *DESCRIPTION* file, 
    - The `packageName` argument in the *R/CohortDiagnostics* file, and
    - The `library()` call at the top of *extras/CodeToRun.R*
    - The name of the *.Rproj* file.
    
3. Open the R project in R studio (e.g. by double-clicking on the *.Rproj* file).

4. Modify *inst/settings/CohortsToCreate.csv* to include only those cohorts you are interested in. Fill in each of the four columns:

    - **atlasId**: The cohort ID in ATLAS.
    - **atlasName**: The full name of the cohort. This will be shown in the Shiny app.
    - **cohortId**: The cohort ID to use in the package. USually the same as the cohort ID in ATLAS.
    - **name**: A short name for the cohort, to use to create file names. do not use special characters.

5. Run this code (note, this can also be found in *extras/PackageMaintenance.R*):

    ```r
    # If ROhdsiWebApi is not yet installed:
    install.packages("devtools")
    devtools::install_github("ROhdsiWebApi")
    
    ROhdsiWebApi::insertCohortDefinitionSetInPackage(fileName = "inst/settings/CohortsToCreate.csv",
                                                     baseUrl = <baseUrl>,
                                                     insertTableSql = TRUE,
                                                     insertCohortCreationR = TRUE,
                                                     generateStats = TRUE,
                                                     packageName = <package name>)
    ```
    
    Where `<baseUrl>` is the base URL for the WebApi instance, for example: "http://server.org:80/WebAPI", and `<package name>` is the name of your new package.

You can now build your package. See *extras/CodeToRun.R* on how to run the package.

