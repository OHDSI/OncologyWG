library(tidyverse)
library(DatabaseConnector)
library(SqlRender)
source("R/plot_fn.R")

##################################################
##### SETUP
##################################################
connectionDetails <-  DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                 server = "dlvidhiomop1.mskcc.org/omop_raw", 
                                                                 user = "", 
                                                                 password = "", 
                                                                 port = 5432)

cdmDatabaseSchema <- "omop_cdm_2"
drug_classification_id_input <- 21601387
condition_id_input <- 197508
regimenIngredientTable <- "test_regimen_ingredient"
writeDatabaseSchema <- "onco_regimen_finder_test"

##################################################
##### PULL DATA
##################################################
sql <- SqlRender::render(SqlRender::readSql("SQL/RawEvents.sql"), cdmDatabaseSchema = cdmDatabaseSchema, writeDatabaseSchema = writeDatabaseSchema, drug_classification_id_input = drug_classification_id_input, condition_id_input = condition_id_input) 
sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)

connection <-  DatabaseConnector::connect(connectionDetails)

executeSql(connection, sql)
sql <- SqlRender::render("SELECT * FROM @writeDatabaseSchema.@rawEvents order by person_id, ingredient_start_date, days_supply", writeDatabaseSchema = writeDatabaseSchema, rawEvents = "raw_events")
rawEvents <- dbGetQuery(connection, sql)

sql <- SqlRender::render("SELECT * FROM @writeDatabaseSchema.@regimenIngredientTable",
                         writeDatabaseSchema = writeDatabaseSchema,
                         regimenIngredientTable = regimenIngredientTable)

regimens <- dbGetQuery(connection, sql)

###################################################
###### MAKE COLOUR PALETTE
###################################################
drugs <- rawEvents %>%
  group_by(concept_name) %>%
  summarise(count = n_distinct(person_id)) %>%
  arrange(desc(count)) %>%
  .$concept_name 

all_colours <- read_rds("markdown/brewer_cols.rds")

cols <- c(all_colours$Set1, all_colours$Set3, all_colours$Dark2) 

colours_to_use <- setNames(cols, drugs[1:length(cols)])


###################################################
#### GENERATE MARKDOWN PLOTS
#################################################
sample_size <- 100

exposure_data <- rawEvents %>%
  tbl_df %>%
  mutate(group = row_number(),
         regimen_group = row_number(),
         type = "exposures") 

regimen_ingredient_data <- regimens %>%
  tbl_df %>%
  select(-regimen, -reg_name) %>%
  rename(concept_name = ingredient,
         ingredient_start_date = regimen_start_date) %>%
  mutate(regimen_group = as.integer(ingredient_start_date),
         group = row_number(),
         days_supply = 0,
         type = "regimen ingredients") 

regimen_name_data <- regimens %>%
  tbl_df %>%
  select(-regimen, -ingredient, -concept_id) %>%
  rename(concept_name = reg_name,
         ingredient_start_date = regimen_start_date) %>%
  mutate(regimen_group = as.integer(ingredient_start_date),
         group = row_number(),
         days_supply = 0,
         type = "hemonc regimen") 



regimens_cis_gem <- regimen_ingredient_data %>%
  arrange(person_id, ingredient_start_date, concept_name) %>% 
  group_by(person_id, ingredient_start_date) %>% 
  mutate(regimen = str_c(concept_name, collapse=", ")) %>% 
  group_by(person_id) %>%
  mutate(num_regimens = n_distinct(regimen)) %>%
  #filter(num_regimens == 1) %>%
  filter(regimen == "cisplatin, gemcitabine") %>% 
  ungroup %>%
  select(-regimen,-num_regimens)

all_data <- bind_rows(exposure_data, regimen_ingredient_data) %>%
  split(.$person_id)

all_data <- bind_rows(exposure_data %>%
                        filter(person_id %in% regimens_cis_gem$person_id), regimens_cis_gem) %>%
  split(.$person_id)


rmarkdown::render("markdown/onco_examples.Rmd", "html_document")

         

