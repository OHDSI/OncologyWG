# Example execution
library(DatabaseConnector)
library(SqlRender)



# ---- Single file -----

# config
file_path <- ""
record_id_prefix <- ""

# Translate to EAV structure
# record_id | mrn | histology_site | item_num | item_name | item_value
df <- NAACCR_to_df(file_path
                   , record_id_prefix)



# Append person_id (requires DB connection)

connectionDetails <- createConnectionDetails(
  dbms="sql server",
  server="",
  user="",
  password="",
  schema =""
)

# Import data directly into database
NAACCR_to_db(file_path
             , record_id_prefix
             , connectionDetails)










