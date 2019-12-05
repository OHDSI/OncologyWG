# Example execution
library(DatabaseConnector)
library(SqlRender)



# ---- Single file -----

# config
file_path <- ""
record_id_prefix <- ""

connectionDetails <- createConnectionDetails(
  dbms="sql server",
  server="",
  user="",
  password="",
  schema ="NAACCR.dbo"
)


# Import data  into database
NAACCR_to_db(file_path
             , record_id_prefix
             , connectionDetails)



# Assign person_id to naaccr_data_points
# requires a table with person_id and mrn which connection can access
# if mrn field has a different name in mapping table, specify in third parameter
assign_person_id(connectionDetails
                 , "thisdb.dbo.person_map_table")







