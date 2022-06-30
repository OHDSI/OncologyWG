
# create the SQLite file

library(dplyr)
library(RSQLite)

concept <- readr::read_csv("inst/csv/concept.csv")
concept_ancestor <- readr::read_csv("inst/csv/concept_ancestor.csv")
concept_relationship <- readr::read_csv("inst/csv/concept_relationship.csv")

drug_exposure <- readr::read_csv("inst/csv/drug_exposure.csv") %>%
  mutate(across(matches("date"), lubridate::mdy))


con <- dbConnect(SQLite(), "inst/sqlite/testdb.sqlite")

dbWriteTable(con, "concept", concept, overwrite = T)
dbWriteTable(con, "concept_relationship", concept_relationship, overwrite = T)
dbWriteTable(con, "concept_ancestor", concept_ancestor, overwrite = T)
dbWriteTable(con, "drug_exposure", drug_exposure, overwrite = T)

dbDisconnect(con)


