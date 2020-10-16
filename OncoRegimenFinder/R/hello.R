# Hello, world!
#
# This is an example function named 'hello'
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'

create_regimens <- function(connectionDetails, cdmDatabaseSchema, writeDatabaseSchema, cohortTable = cohortTable, regimenTable = regimenTable, regimenIngredientTable = regimenIngredientTable, vocabularyTable = vocabularyTable, drug_classification_id_input, date_lag_input, sample_size = 999999999999, regimen_repeats = 5, generateVocabTable = F){

  connection <-  DatabaseConnector::connect(connectionDetails)

  sql <- SqlRender::loadRenderTranslateSql("CohortBuild.sql", packageName = "OncoRegimenFinder", dbms = "redshift", cdmDatabaseSchema = cdmDatabaseSchema, writeDatabaseSchema = writeDatabaseSchema, cohortTable = cohortTable, regimenTable = regimenTable, drug_classification_id_input = drug_classification_id_input)

  DatabaseConnector::executeSql(connection, sql)

  sql <- SqlRender::render("SELECT max(rn) FROM @writeDatabaseSchema.@regimenTable;", writeDatabaseSchema = writeDatabaseSchema, regimenTable = regimenTable)

  max_id <- DatabaseConnector::dbGetQuery(connection, sql)

  message(paste0("Cohort contains ", max_id$max, " subjects"))

  id_groups <- c(seq(1, max_id$max, sample_size), max_id$max + 1)

  sql <- SqlRender::render("
    DROP TABLE IF EXISTS  @writeDatabaseSchema.@regimenTable_f;
    CREATE TABLE @writeDatabaseSchema.@regimenTable_f (
       person_id bigint not null,
       drug_era_id bigint,
       concept_name varchar(max),
       ingredient_start_date date not null
    ) DISTKEY(person_id) SORTKEY(person_id, ingredient_start_date);", regimenTable_f = paste0(regimenTable,"_f"), writeDatabaseSchema = writeDatabaseSchema)

  DatabaseConnector::executeSql(connection, sql)

  for(g in c(1:(length(id_groups)-1))){

    start_id = id_groups[g]
    end_id = id_groups[g+1] - 1

    message(paste0("Processing persons ",start_id," to ",end_id))

    sql <- SqlRender::render("DROP TABLE IF EXISTS @writeDatabaseSchema.@sampledRegimenTable;
                              SELECT person_id, drug_era_id, concept_name, ingredient_start_date
                              into @writeDatabaseSchema.@sampledRegimenTable
                              FROM @writeDatabaseSchema.@regimenTable
                              WHERE rn >= @start AND rn <= @end;",
                             writeDatabaseSchema = writeDatabaseSchema, regimenTable = regimenTable, sampledRegimenTable = paste0(regimenTable,"_sampled"), start = start_id, end = end_id)

    DatabaseConnector::executeSql(connection, sql)

    sql <- SqlRender::loadRenderTranslateSql("RegimenCalc2.sql", packageName = "OncoRegimenFinder", dbms = "redshift",
                             writeDatabaseSchema = writeDatabaseSchema, regimenTable = paste0(regimenTable,"_sampled"), date_lag_input = date_lag_input)
    # sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)

    for(i in c(1:regimen_repeats)){DatabaseConnector::executeSql(connection, sql)}

    sql <- SqlRender::render("insert into @writeDatabaseSchema.@regimenTable_f
                              (select *
                              from @writeDatabaseSchema.@sampledRegimenTable);",  writeDatabaseSchema = writeDatabaseSchema, sampledRegimenTable = paste0(regimenTable,"_sampled"), regimenTable_f = paste0(regimenTable,"_f"))

    DatabaseConnector::executeSql(connection, sql)

  }


  if(generateVocabTable){


    sql <- SqlRender::loadRenderTranslateSql("RegimenVoc.sql", packageName = "OncoRegimenFinder", dbms = "redshift", cdmDatabaseSchema = cdmDatabaseSchema, writeDatabaseSchema = writeDatabaseSchema, vocabularyTable = vocabularyTable)
    sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)
    DatabaseConnector::executeSql(connection, sql)

  }

  sql <- SqlRender::loadRenderTranslateSql("RegimenFormat.sql", packageName = "OncoRegimenFinder", dbms = "redshift", writeDatabaseSchema = writeDatabaseSchema, cohortTable = cohortTable, regimenTable = paste0(regimenTable,"_f"), regimenIngredientTable = regimenIngredientTable, vocabularyTable = vocabularyTable)

  DatabaseConnector::executeSql(connection, sql)


}
