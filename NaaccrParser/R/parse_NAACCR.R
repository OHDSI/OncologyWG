NAACCR_to_db <- function(file_path
                         ,record_id_prefix = NULL
                         ,connectionDetails){


  conn <- DatabaseConnector::connect(connectionDetails)

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


  ret_df <- data.frame(matrix(nrow= 0, ncol = length(col_names)))
  names(ret_df) <- col_names



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



      if(nrow(tmp_df) > 0){
        # Append rows to result dataframe

        DatabaseConnector::insertTable(connection = conn,
                                      tableName = "naaccr_data_points",
                                      data = tmp_df,
                                      dropTableIfExists = FALSE,
                                      createTable = FALSE,
                                      tempTable = FALSE,
                                      useMppBulkLoad = FALSE)

      }

    }

  }

  print("Completed")

}




assign_person_id <- function(connectionDetails
                             ,person_map_table
                             ,person_map_field = "MRN"){

  # requires DB.schema.table format
  curr_sql <- SqlRender::render("UPDATE naaccr_data_points SET person_id = x.person_id FROM @table x WHERE naaccr_data_points.mrn = x.@field;"
                                ,field = person_map_field
                                ,table = person_map_table)

  conn <- DatabaseConnector::connect(connectionDetails)
  person_map <- DatabaseConnector::executeSql(connection = conn
                                            ,sql = curr_sql)
  DatabaseConnector::disconnect(conn)
}





