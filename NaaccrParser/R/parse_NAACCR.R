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


append_condition_concept <- function(df
                                     ,connectionDetails
                                     ,vocabSchema){



  # requires DB.schema.table format
  curr_sql <- "SELECT CONCEPT_CODE, CONCEPT_ID
              FROM @vocabSchema.concept
              WHERE concept_class_id = 'ICDO Condition';"

  sql <- SqlRender::render(sql=curr_sql, vocabSchema = vocabSchema)

  conn <- DatabaseConnector::connect(vocabConnectionDetails)
  res_df <- DatabaseConnector::querySql(connection = conn
                                        ,sql = sql)
  DatabaseConnector::disconnect(conn)

  # Append columns
  df <- merge(df, res_df
              , by.x= "histology_site", by.y = "CONCEPT_CODE"
              , all.x = TRUE
  )

  return(df)
}






get_schema_for_record <- function(df){

  res_schema <- ""

  site <- df$item_value[df$item_num == 400]
  histology <- df$item_value[df$item_num == 522]

  return_df <- schema_map[schema_map$site_range_start <= site,]
  return_df <- return_df[return_df$site_range_end >= site,]
  return_df <- return_df[return_df$hist_range_start <= histology,]
  return_df <- return_df[return_df$hist_range_end >= histology,]

  if(nrow(return_df) == 1){
    res_schema <- return_df$id[1]
  }


  if(nrow(return_df) > 1){
    disc_map <- schema_disc_map[schema_disc_map$schema %in% return_df$id,]
    item_num <- disc_map$discrim_item_num[1]
    item_val <- df$item_value[which(df$item_num == item_num)]
    if(length(item_val) == 1){
      res_schema <- disc_map$schema[which(as.numeric(disc_map$value) == as.numeric(item_val))]
    }else{
      res_schema <- ""
    }

  }

  return(res_schema)

}




append_schema <- function(df){

  df$schema <- ""

  rec_list <- unique(df$record_id)

  for(i in 1:length(rec_list)){
    curr_record <- df[which(df$record_id == rec_list[i]),]

    ret_schema <- get_schema_for_record(curr_record)


    df$schema[which(df$record_id == rec_list[i])] <- ret_schema
  }

  return(df)
}










