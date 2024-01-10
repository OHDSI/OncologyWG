library(SqlRender)
library(jsonlite)


# Helpers -----------------------------------------------------------------

# TODO change everything about this to "OncAnalysisDetails"
#' Get Oncology Validation query details
#'
#' @return
#' @export
#'
#' @examples
getOncAnalysisQueries <- function() {
  read.csv(file.path('./inst/csv/onc_analysis_queries.csv'))
}


#' Get the analysis text from a composite analysis file
#'
#' @param analysisNumber
#'
#' @return (string) A SQL script as a string
#' 

getAnalysisText <- function(analysisNumber) {
  fp <- file.path('.', 'inst', 'sql', 'composite_analyses', paste0(analysisNumber, '.sql'))
  readChar(fp, file.info(fp)$size)
}


#' Get the query text from a base query file
#'
#' @param queryNumber
#'
#' @return (string) A SQL script as a string
#' 

getQueryText <- function(queryNumber) {
  fp <- file.path('.', 'inst', 'sql', 'queries', paste0(queryNumber, '.sql'))
  readChar(fp, file.info(fp)$size)
}

#' Title
#'
#' @param connectionDetails 
#' @param scratchDatabaseSchema 
#'
#' @return
#' @export
#'
#' @examples
getExistingQueryNumbers <- function(connectionDetails, scratchDatabaseSchema) {
  # REad table names from scratchDatabase
  # There is not way to translate between these operations, so will need one for each supported database
  
  sql <- render('SHOW TABLES FROM @scratchDatabaseSchema LIKE \'onc_val_*\'',
                scratchDatabaseSchema = scratchDatabaseSchema)
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  queryTables <- DatabaseConnector::querySql(conn, sql = sql)$TABLENAME
  as.numeric(gsub(".*_([0-9]+)$", "\\1", queryTables))
}


# DDL Handlers ------------------------------------------------------------

# Create composite analysis table
#'
#' @param connectionDetails 
#' @param resultsDatabaseSchema 
#' @param createTable 
#'
#' @return
#' @export
#'
#' @examples
#' 

createAnalysisTable <- function(connectionDetails, resultsDatabaseSchema, createTable = TRUE) {
  if (isTRUE(createTable)) {
    fp <- file.path('.', 'inst', 'sql', 'onc_validation_analysis_ddl.sql')
    sql <- readChar(fp, file.info(fp)$size)
    rendered <- render(sql, resultsDatabaseSchema = resultsDatabaseSchema)
    renderedTranslated <- translate(rendered, targetDialect = connectionDetails$dbms)
    conn <- DatabaseConnector::connect(connectionDetails)
    on.exit(DatabaseConnector::disconnect(conn))
    DatabaseConnector::executeSql(conn, sql = renderedTranslated)
    }
}


#' Create composite analysis results table
#'
#' @param connectionDetails 
#' @param resultsDatabaseSchema 
#' @param overwrite 
#'
#' @return
#' @export
#'
#' @examples
#' 

createResultsTable <- function(connectionDetails, resultsDatabaseSchema, overwrite = FALSE) {
  fp <- file.path('.', 'inst', 'sql', 'onc_validation_results_ddl.sql')
  sql <- readChar(fp, file.info(fp)$size)
  rendered <- render(sql, resultsDatabaseSchema = resultsDatabaseSchema)
  renderedTranslated <- translate(rendered, targetDialect = connectionDetails$dbms)
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  exists = DatabaseConnector::existsTable(conn, databaseSchema = resultsDatabaseSchema, tableName = 'onc_validation_results')
  if (!overwrite && exists) {
    message("Onc Validation results exists. Set overwrite to TRUE to rebuild.")
    return(0)
  }
  DatabaseConnector::executeSql(conn, sql = renderedTranslated)
}


# Execution Handlers ------------------------------------------------------

executeAnalysis <- function(connectionDetails, 
                analysisNumber,
                cdmDatabaseSchema = cdmDatabaseSchema,
                vocabDatabaseSchema = vocabDatabaseSchema,
                scratchDatabaseSchema = scratchDatabaseSchema,
                resultsDatabaseSchema = resultsDatabaseSchema) {
  
  composites_path <- file.path('./inst/json/onc_analysis_composite.json')
  
  composites <- fromJSON(composites_path)$composite_analyses
  
  requisiteQueryNumbers <-  composites$queries[composites['analysis_id'] == analysisNumber][[1]]
  
  existingQueryNumbers <- getExistingQueryNumbers(connectionDetails, scratchDatabaseSchema)
  
  missingQueries <- which(!requisiteQueryNumbers %in% existingQueryNumbers)
  
  if (length(missingQueries)) {
    message("Executing required queries")
    lapply(missingQueries, function(x) {
      executeQuery(connectionDetails,
                   queryNumber = x,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   vocabDatabaseSchema = vocabDatabaseSchema,
                   scratchDatabaseSchema = scratchDatabaseSchema)
      })
  }
  message("All requisite queries executed.")
  
  
  renderedAnalysisText <- render(getAnalysisText(analysisNumber),
                                 scratchDatabaseSchema = scratchDatabaseSchema)
  
  renderedInsertAnalysisText <- render(getAnalysisText('analysisInsert'),
                                    insertSchema = scratchDatabaseSchema,
                                    analysisText = renderedAnalysisText)
  
  translatedRenderedInsertAnalysisText <- translate(renderedInsertAnalysisText, targetDialect = connectionDetails$dbms)
  
  message(paste0("Executing analysis ", analysisNumber, ", writing to ", resultsDatabaseSchema, ".onc_validation_results"))
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::executeSql(conn, sql = translatedRenderedInsertAnalysisText)
  analysisNumber  
}


#' Title
#'
#' @param connectionDetails 
#' @param queryNumber 
#' @param cdmDatabaseSchema 
#' @param vocabDatabaseSchema 
#' @param scratchDatabaseSchema 
#'
#' @return
#' 

executeQuery <- function(connectionDetails,
                         queryNumber,
                         cdmDatabaseSchema = cdmDatabaseSchema,
                         vocabDatabaseSchema = vocabDatabaseSchema,
                         scratchDatabaseSchema = scratchDatabaseSchema) {
  
  queries <- getOncAnalysisQueries()
  
  queryTableName <- paste("onc_val", queries$category[queries['granular_analysis_id'] == queryNumber], queryNumber, sep ='_')
  
  
  renderedQueryText <- render(getQueryText(queryNumber),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             vocabDatabaseSchema = vocabDatabaseSchema)
  
  renderedInsertQueryText <- render(getQueryText('basicInsert'),
                                    insertSchema = scratchDatabaseSchema,
                                    queryTableName = queryTableName,
                                    queryText = renderedQueryText)
  translatedRenderedInsertQueryText <- translate(renderedInsertQueryText, targetDialect = connectionDetails$dbms)
  
  message(paste0("Executing query ", queryNumber, ", writing to ", scratchDatabaseSchema, ".", queryTableName))
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  DatabaseConnector::executeSql(conn, sql = translatedRenderedInsertQueryText)
  queryTableName
}





# Example execution -------------------------------------------------------


connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = 'spark',
  connectionString = keyring::key_get("databricks-connection-string"),
  pathToDriver = "C:\\R\\"
)
# @cdmDatabseSchema
# @vocabDatabaseSchema

cdmDatabaseSchema <- vocabDatabaseSchema <- 'ctsi.trdwlegacyred'

# @scratchDatabaseSchema
scratchDatabaseSchema <- resultsDatabaseSchema <- 'ctsi.kzollo'



# TODO switch to rebuild all queries... does this go in the analysis section or the query?



createAnalysisTable(connectionDetails, resultsDatabaseSchema)

createResultsTable(connectionDetails, resultsDatabaseSchema)


oncAnalysisQueriesCsv <- getOncAnalysisQueries()
oncAnalysisQueriesCsv <- oncAnalysisQueriesCsv[, -c(2, 3)]

conn <- DatabaseConnector::connect(connectionDetails)

# Populate ONC_analysis with data from ONC_ANALYSIS_QUERIES. from above
DatabaseConnector::insertTable(
  connection        = connection,
  databaseSchema    = resultsDatabaseSchema,
  tableName         = "ONC_VALIDATION_ANALYSIS",
  data              = oncAnalysisQueriesCsv,
  dropTableIfExists = FALSE,
  createTable       = FALSE,
  tempTable         = FALSE
)

DatabaseConnector::disconnect(conn)


# User asks: How many cancer diagnosis records are in my data?

executeAnalysis(connectionDetails,  analysisNumber = 2,
                cdmDatabaseSchema = cdmDatabaseSchema,
                vocabDatabaseSchema = vocabDatabaseSchema,
                scratchDatabaseSchema = scratchDatabaseSchema,
                resultsDatabaseSchema = resultsDatabaseSchema)
