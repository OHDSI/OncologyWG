# Example execution





# ---- Single file -----

# config
file_path <- ""
record_id_prefix <- "tmc2016"

# Translate to EAV structure
# record_id | mrn | histology_site | item_num | item_name | item_value
df <- NAACCR_to_df(file_path
                   , record_id_prefix)


# write to file
write.csv(df,
          file = "",
          row.names = FALSE
          )




# --- Add ons ----


# Append schema

df <- append_schema(df)


# Append person_id (requires DB connection)

connectionDetails <- createConnectionDetails(
  dbms="sql server",
  server="",
  user="",
  password=""
)

# append person_id
# assumes you have a table in database that maps mrn to person_id

df <- append_person_id(df = df
                       ,connectionDetails = connectionDetails
                       ,person_map_table = ""
                       ,person_map_field = "")



# Append ICDO condition concept

df <- append_condition_concept(df = df
                               ,connectionDetails = connectionDetails
                               ,vocabSchema = "")
















