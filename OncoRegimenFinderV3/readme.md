OncoRegimenFinder
==============================

This package identifies oncology regimens. Firstly, it identifies all patients who have been exposed with an Antineoplastic Agent (ATC code). Then it collapses the antineoplastic agents into regimens when there is a date difference less that @date_lag_input(30days is used as standard). 

Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: Amazon RedShift.
- R version 3.5.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

See [this video](https://youtu.be/K9_0s2Rchbo) for instructions on how to set up the R environment on Windows.

How to run
==========
1. In `R`, use the following code to install the dependencies:

	```r
	install.packages("devtools")
	install.packages("tidyverse")
	library(devtools)
	library(tidyverse)
	install_github("ohdsi/SqlRender", ref = "v1.5.2")
	install_github("ohdsi/DatabaseConnector", ref = "v2.2.0")
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
	
	#For the first you should have it as TRUE. When you re run the package set it as FALSE.
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
	```


