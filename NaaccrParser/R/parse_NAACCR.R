

# main function for parsing fixed-width data
NAACCR_to_db <- function(file_path
                         ,record_id_prefix = NULL
                         ,connectionDetails){



  # Get NAACCR version
  # 160 = v16, 170 = v17, etc
  naaccr_version <- substr(readLines(file_path, n=1), 17,19)

  # Load record layout
  record_layout <- NULL
  if(naaccr_version == "150"){
    record_layout <- NAACCR_RL_v15
  }else if (naaccr_version == "160"){
    record_layout <- NAACCR_RL_v16
  }else if (naaccr_version == "180"){
    record_layout <- NAACCR_RL_v18
  }


  if(!is.data.frame(record_layout) ){
    print("Unrecognized version ")
  }

  # Filter out text fields. TODO: Parse into notes
  record_layout <- record_layout[record_layout$length < 70,]

  # Get file width
  wid <- nchar(readLines(file_path, n=1))

  # Load file as rows
  curr  <- data.frame(readLines(file_path), stringsAsFactors = FALSE)

  # Change name of text blob column
  names(curr)[1] <- "raw"

  # Add record index
  record_index <- as.character(c(1:nrow(curr)))

  if (missing(record_id_prefix) || is.null(record_id_prefix)) {
    record_index <- paste0( tools::file_path_sans_ext(basename(file_path))
                            ,"/"
                            ,record_index)
  }else{
    record_index <- paste0( record_id_prefix
                            ,"/"
                            ,tools::file_path_sans_ext(basename(file_path))
                            ,"/"
                            ,record_index)
  }

  curr <- cbind(curr, record_index)


  # Create result dataframe
  col_names <-  c("person_id"
                  ,"record_id"
                  ,"mrn"
                  ,"histology_site"
                  ,"naaccr_item_number"
                  ,"naaccr_item_name"
                  ,"naaccr_item_value" )


 # ret_df <- data.frame(matrix(nrow= 0, ncol = length(col_names)))
#  names(ret_df) <- col_names


  conn <- DatabaseConnector::connect(connectionDetails)



  # Loop through each row
  for (i in 1:nrow(curr)){

    curr_row <- curr[i,]

    tmp_df <- data.frame(matrix(nrow= nrow(record_layout), ncol = length(col_names)))
    names(tmp_df) <- col_names



    # Get all (naaccr_item_number, naaccr_item_value) pairs
    for(j in 1:nrow(record_layout)){
      curr_item <- record_layout[j,]

      tmp_df$naaccr_item_number[j] <- curr_item$Item_Num
      tmp_df$naaccr_item_name[j] <- curr_item$Item_Name
      tmp_df$naaccr_item_value[j] <- trimws(substr(curr_row$raw, curr_item$col_start, curr_item$col_end))
    }



    # Restrict to records with specific fields populated (for effiency)
    hist3 <- tmp_df$naaccr_item_value[tmp_df$naaccr_item_number == 521]
    site <- tmp_df$naaccr_item_value[tmp_df$naaccr_item_number == 400]
    dxDate <- tmp_df$naaccr_item_value[tmp_df$naaccr_item_number == 390]

    if(
      # If hist/grade is populated
      nchar(hist3) > 3
      &
      # If site is populated
      nchar(site) > 3
      &
      # If diag date is populated
      nchar(dxDate) > 7
    )
    {

      # Populate static rows

      # Record_id
      tmp_df$record_id <- curr_row$record_index

      # MedRedNum
      tmp_df$mrn <- tmp_df$naaccr_item_value[tmp_df$naaccr_item_number == 2300]


      # histology_site
      tmp_df$histology_site <- paste0(
        paste0(
          substr(hist3, 0, 4)
          ,"/"
          ,substr(hist3, 5, 6)
        )
        ,"-"
        ,substr(site, 0,3)
        ,"."
        ,substr(site, 4,5)
      )

      # Remove empty fields
      tmp_df <- tmp_df[nchar(tmp_df$naaccr_item_value) > 0,]

      # Workaround for ingestion bug (R setting person_id to 'logi' which DB doesn't like)
      tmp_df$person_id <- as.integer(tmp_df$person_id)

      if(nrow(tmp_df) > 0){
        # Append rows to result dataframe




        DatabaseConnector::insertTable(connection = conn,
                                       tableName = "naaccr_data_points",
                                       databaseSchema = "NAACCR_OMOP.dbo",
                                       data = tmp_df,
                                       dropTableIfExists = FALSE,
                                       createTable = FALSE,
                                       tempTable = FALSE)



        print(paste0("Row: ",i, "--", file_path, ": inserted ", nrow(tmp_df), " rows"))


      }

    }

  }
  DatabaseConnector::disconnect(conn)

}



# optional function  to populate person_id after ingestion
assign_person_id <- function(connectionDetails
                             ,ndp_schema
                             ,person_map_schema
                             ,person_map_table
                             ,person_map_field = "MRN"){

  # requires DB.schema.table format
  curr_sql <- SqlRender::render("UPDATE @ndp_schema.naaccr_data_points SET person_id = x.person_id FROM @person_map_schema.@table x WHERE naaccr_data_points.mrn = x.@field;"
                                ,ndp_schema = ndp_schema
                                ,person_map_schema = person_map_schema
                                ,field = person_map_field
                                ,table = person_map_table)

  conn <- DatabaseConnector::connect(connectionDetails)
  person_map <- DatabaseConnector::executeSql(connection = conn
                                            ,sql = curr_sql)
  DatabaseConnector::disconnect(conn)
}




# main function for parsing XML
parse_XML_to_DB <- function(file_path
                             ,record_id_prefix = NULL
                             ,connectionDetails){

  if(is.null(file_path)){
    print("error: NULL file_path")
    exit()
  }

  if(is.null(connectionDetails)){
    print("Error: NULL connectionDetails")
    exit()
  }

  file_name <- basename(file_path_sans_ext(file_path))


  if(!is.null(record_id_prefix)){
    record_id_prefix <- paste0(file_name, "_")
  }else{
    record_id_prefix <- paste0(record_id_prefix, "_")
  }





  a <- XML::xmlParse(file_path)


  # START - test check file typ
  t1 <- file_ext("//nectsifs/Import/NAACCR_share/2020_2021.xml")


  b <- XML::xmlToList(a)


  itemNum_to_NaaccrID_v23 <- read.csv("//nectsifs/Import/NAACCR_2023/itemNum_to_NaaccrID_v23.csv")





  # 1) --------- Data set metadata -------------- #

  # create result df
  mat <- matrix(nrow = 0, ncol = 2)
  items_df <- as.data.frame(mat)

  for(i in 1:length(b)){
    if (names(b[i]) == 'Item'){
      curr <- unlist(b[i])
      items_df <- rbind(items_df, curr)
    }
  }
  names(items_df) <- c("value", "naaccrId")


  # create result df
  mat <- matrix(nrow = 0, ncol = 4)
  pat_df <- as.data.frame(mat)
  names(pat_df) <- c("pat_id","tumor_index", "value", "naaccrId")



  # make template for recreating
  pat_df_template <- pat_df

  # make final output table
  pat_df_output <- pat_df


  # split up parsing for easier computation
  patient_count <- length(b)

  start_index <- 1
  end_index <- start_index + 100




  while(start_index < patient_count){


    pat_df <- pat_df_template


    end_index <- start_index + 100
    if(end_index > patient_count){
      end_index <- patient_count
    }

    for(j in start_index:end_index){

      if (names(b[j]) == 'Patient'){

        curr_pat <- b[j]$Patient

        tumor_number <- 1

        for(i in 1:length(curr_pat)){
          if (names(curr_pat[i]) == 'Item'){
            curr <- unlist(curr_pat[i])
            curr <- c(j,tumor_number, curr)
            pat_df <- rbind(pat_df, curr)
          }
          else if (names(curr_pat[i]) == 'Tumor'){
            curr_tumor <- curr_pat[i]$Tumor


            for(k in 1:length(curr_tumor)){
              curr <- unlist(curr_tumor[k])
              curr <- c(j, tumor_number, curr)
              pat_df <- rbind(pat_df, curr)
            }
            tumor_number <- tumor_number + 1
          }
        }}
    }

    names(pat_df) <- c("pat_id","tumor_index", "value", "naaccrId")

    # incrementally add chunks to output for efficiency
    pat_df_output <- rbind(pat_df_output, pat_df)
    start_index <- end_index + 1


  }


  names(pat_df_output) <- c("pat_id","tumor_index", "value", "naaccrId")


  timestamp()



  curr <- merge(pat_df_output, itemNum_to_NaaccrID_v23, by.x = "naaccrId", by.y = "XML.NAACCR.ID", all.x = TRUE)


  # duplicates for some reason - removing
  curr <- unique(curr)

  # ----

  #temp for testing


  var_check <- unique(curr[,(c("naaccrId","Data.Item.Number"))])

  #curr <- zpat

  #-----



  # New
  index_map <- unique(curr[,c("pat_id","tumor_index")])
  index_map$record_index <- seq(nrow(index_map))

  index_map$record_id = paste0( record_id_prefix
                                ,"/"
                                ,index_map$record_index)


  curr <- merge(curr, index_map, by=c("pat_id", "tumor_index"))

  #merge(curr, index_map, by.x = "naaccrId", by.y = "XML.NAACCR.ID", all.x = TRUE)

  # Get static values

  index_map$mrn <- ''
  index_map$histology_site <- ''

  mrn_list <- subset(curr, Data.Item.Number == 21)
  site_list <- subset(curr, Data.Item.Number == 400)
  hist_list <- subset(curr, Data.Item.Number == 522)
  behav_list <- subset(curr, Data.Item.Number == 523)

  for(i in 1:nrow(index_map)){
    tmp_record_id <- index_map$record_id[i]


    index_map$mrn[i] <- mrn_list$value[mrn_list$record_id == tmp_record_id]

    tmp_site <- site_list$value[site_list$record_id == tmp_record_id]

    index_map$histology_site[i]  <- paste0(
      paste0(
        hist_list$value[hist_list$record_id == tmp_record_id]
        ,"/"
        ,behav_list$value[behav_list$record_id == tmp_record_id]
      )
      ,"-"
      ,substr(tmp_site, 0,3)
      ,"."
      ,substr(tmp_site, 4,5)
    )

  }

  # make person_id placeholder
  index_map$person_id <- rep('', nrow(index_map))


  tmp1 <- index_map[,c("person_id", "record_id", "mrn", "histology_site")]
  tmp2 <- curr[,c("record_id", "Data.Item.Number", "naaccrId", "value")]
  names(tmp2) <- c("record_id", "naaccr_item_number", "naaccr_item_name", "naaccr_item_value")

  # union is to prevent column reordering
  res <- merge(tmp1, tmp2, by = "record_id")[, union(names(tmp1), names(tmp2))]

  ## -- CLEAN

  res$naaccr_item_value <- trimws(res$naaccr_item_value)

  # Remove empty fields
  res <- res[nchar(res$naaccr_item_value) > 0,]

  conn <- DatabaseConnector::connect(connectionDetails)

  if(nrow(res) > 0){
    # Append rows to result dataframe

    DatabaseConnector::insertTable(connection = conn,
                                   tableName = "naaccr_data_points",
                                   databaseSchema = "NAACCR_OMOP.dbo",
                                   data = res,
                                   dropTableIfExists = FALSE,
                                   createTable = FALSE,
                                   tempTable = FALSE)


  }

  DatabaseConnector::disconnect(conn)

  print(paste0("Completed ", file_name, ": inserted ", nrow(res), " rows"))


}

# umbrella function to parse directory of source files
# can be either fixed width or XML
parse_directory <- function(dir_path
                            ,connectionDetails){


  tmp_files <- list.files(dir_path, full.names = TRUE)


  for(i in 1:length(tmp_files)){
    curr_file <- tmp_files[i]


    print(paste0("Parsing: ", curr_file))

    fext <- file_ext(curr_file)

    if(fext == "XML"){
      parse_XML_to_DB(file_path = curr_file
                      ,record_id_prefix = NULL
                      ,connectionDetails = connectionDetails)
    }else{
      NAACCR_to_db(file_path = curr_file
                   ,record_id_prefix = NULL
                   ,connectionDetails = connectionDetails)
    }

  }








}







