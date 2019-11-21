library(DatabaseConnector)
library(SqlRender)




NAACCR_to_df <- function(file_path
                         ,record_id_prefix = NULL){


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
  col_names <-  c("record_id"
                  ,"mrn"
                  ,"histology_site"
                  ,"item_num"
                  ,"item_name"
                  ,"item_value" )


  ret_df <- data.frame(matrix(nrow= 0, ncol = length(col_names)))
  names(ret_df) <- col_names



  # Loop through each row
  for (i in 1:nrow(curr)){

    curr_row <- curr[i,]

    tmp_df <- data.frame(matrix(nrow= nrow(record_layout), ncol = length(col_names)))
    names(tmp_df) <- col_names

    # Get all (item_num, item_value) pairs
    for(j in 1:nrow(record_layout)){
      curr_item <- record_layout[j,]

      tmp_df$item_num[j] <- curr_item$Item_Num
      tmp_df$item_name[j] <- curr_item$Item_Name
      tmp_df$item_value[j] <- trimws(substr(curr_row$raw, curr_item$col_start, curr_item$col_end))
    }



    # Restrict to records with specific fields populated (for effiency)

    if(
      # If hist/grade is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 521]) > 3
      &
      # If site is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 400]) > 2
      &
      # If diag date is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 390]) > 2
    )
    {

      # Populate static rows

      # Record_id
      tmp_df$record_id <- curr_row$record_index

      # MedRedNum
      tmp_df$mrn <- tmp_df$item_value[tmp_df$item_num == 2300]


      # histology_site
      tmp_df$histology_site <- paste0(
        paste0(
          substr(tmp_df$item_value[tmp_df$item_num == 521], 0, 4)
          ,"/"
          ,substr(tmp_df$item_value[tmp_df$item_num == 521], 5, 6)
        )
        ,"-"
        ,substr(tmp_df$item_value[tmp_df$item_num == 400], 0,3)
        ,"."
        ,substr(tmp_df$item_value[tmp_df$item_num == 400], 4,5)
      )

      # Remove empty fields
      tmp_df <- tmp_df[nchar(tmp_df$item_value) > 0,]



      if(nrow(tmp_df) > 0){
        # Append rows to result dataframe
        ret_df <- rbind(ret_df, tmp_df)

      }

    }

  }

  return(ret_df)
}



NAACCR_to_db <- function(file_path
                         ,record_id_prefix = NULL
                         ,connectionDetails){


  conn <- connect(connectionDetails)

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
                  ,"item_num"
                  ,"item_name"
                  ,"item_value" )


  ret_df <- data.frame(matrix(nrow= 0, ncol = length(col_names)))
  names(ret_df) <- col_names



  # Loop through each row
  for (i in 1:nrow(curr)){

    curr_row <- curr[i,]

    tmp_df <- data.frame(matrix(nrow= nrow(record_layout), ncol = length(col_names)))
    names(tmp_df) <- col_names

    # Get all (item_num, item_value) pairs
    for(j in 1:nrow(record_layout)){
      curr_item <- record_layout[j,]

      tmp_df$item_num[j] <- curr_item$Item_Num
      tmp_df$item_name[j] <- curr_item$Item_Name
      tmp_df$item_value[j] <- trimws(substr(curr_row$raw, curr_item$col_start, curr_item$col_end))
    }



    # Restrict to records with specific fields populated (for effiency)

    if(
      # If hist/grade is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 521]) > 3
      &
      # If site is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 400]) > 2
      &
      # If diag date is populated
      nchar(tmp_df$item_value[tmp_df$item_num == 390]) > 2
    )
    {

      # Populate static rows

      # Record_id
      tmp_df$record_id <- curr_row$record_index

      # MedRedNum
      tmp_df$mrn <- tmp_df$item_value[tmp_df$item_num == 2300]


      # histology_site
      tmp_df$histology_site <- paste0(
        paste0(
          substr(tmp_df$item_value[tmp_df$item_num == 521], 0, 4)
          ,"/"
          ,substr(tmp_df$item_value[tmp_df$item_num == 521], 5, 6)
        )
        ,"-"
        ,substr(tmp_df$item_value[tmp_df$item_num == 400], 0,3)
        ,"."
        ,substr(tmp_df$item_value[tmp_df$item_num == 400], 4,5)
      )

      # Remove empty fields
      tmp_df <- tmp_df[nchar(tmp_df$item_value) > 0,]



      if(nrow(tmp_df) > 0){
        # Append rows to result dataframe

        # temp fix to match db cols
        names(tmp_df) <-  c("person_id"
                            ,"record_id"
                            ,"mrn"
                            ,"histology_site"
                            ,"naaccr_item_number"
                            ,"naaccr_item_name"
                            ,"naaccr_item_value" )

        insertTable(connection = conn,
                    tableName = "naaccr_data_points",
                    data = tmp_df,
                    dropTableIfExists = FALSE,
                    createTable = FALSE,
                    tempTable = FALSE,
                    useMppBulkLoad = FALSE)

      }

    }

  }

  print("done-zo")
}



append_person_id <- function(df
                             ,connectionDetails
                             ,person_map_table
                             ,person_map_field = "MRN"){

  # Get person map

  # requires DB.schema.table format
  curr_sql <- SqlRender::render("SELECT person_id, @field FROM @table;"
                                ,field = person_map_field
                                ,table = person_map_table)

  conn <- DatabaseConnector::connect(connectionDetails)
  person_map <- DatabaseConnector::querySql(connection = conn
                                            ,sql = curr_sql)
  DatabaseConnector::disconnect(conn)

  # Append column
    # Funky approach to prevent merge() from reordering columns
  tmp <- merge(df, person_map
             , by.x= "mrn", by.y = person_map_field
             , all.x = TRUE
             )
  df$person_id <- tmp$PERSON_ID


  return(df)
}









