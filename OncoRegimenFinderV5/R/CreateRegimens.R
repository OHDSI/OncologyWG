#' Create an oncology drug regimen table in a `writeDatabaseSchema` database
#'
#' @description
#' Creates treatment regimens
#'
#' @param connectionDetails
#' @param writeDatabaseSchema
#' @param rawEventTable
#' @param dateLagInput
#' @param generateVocabTable
#' @param sampleSize
#' @param cdmDatabaseSchema
#' @param cohortTable
#' @param regimenTable
#' @param regimenIngredientTable
#' @param vocabularyTable
#' @param cancerConceptId
#' @param generateRawEvents
#' @param keepSteroids Boolean parameter if TRUE algorithm will look for steroids along other drugs
#'
#' @return
#' This function does not return a value. It is called for its side effect of
#' creating a new SQL table called `regimenIngredientTable` in `writeDatabaseSchema`.
#' @export

createRegimens <- function(connectionDetails,
                           cdmDatabaseSchema,
                           writeDatabaseSchema,
                           cohortTable,
                           rawEventTable,
                           regimenTable,
                           regimenIngredientTable,
                           vocabularyTable,
                           cancerConceptId = 4115276,
                           dateLagInput = 30,
                           generateVocabTable = FALSE,
                           generateRawEvents = FALSE,
                           keepSteroids = FALSE,
                           useHemoncToPullDrugs = FALSE
                           ){




  connection <-  DatabaseConnector::connect(connectionDetails)

  createCohortTable(connection,
                    cdmDatabaseSchema,
                    writeDatabaseSchema,
                    cohortTable,
                    regimenTable,
                    keepSteroids,
                    useHemoncToPullDrugs
  )

  createRegimenCalculation(connection = connection,
                           writeDatabaseSchema = writeDatabaseSchema,
                           regimenTable = regimenTable,
                           dateLagInput= dateLagInput)

  createRawEvents(connection = connection,
                  rawEventTable = rawEventTable,
                  cancerConceptId = cancerConceptId,
                  writeDatabaseSchema = writeDatabaseSchema,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  dateLagInput = dateLagInput,
                  generateRawEvents = generateRawEvents)

  createVocabulary(connection = connection,
                   writeDatabaseSchema = writeDatabaseSchema,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   vocabularyTable = vocabularyTable,
                   generateVocabTable = generateVocabTable)

  createRegimenFormatTable(connection = connection,
                           writeDatabaseSchema = writeDatabaseSchema,
                           cohortTable = cohortTable,
                           regimenTable = regimenTable,
                           regimenIngredientTable = regimenIngredientTable,
                           vocabularyTable = vocabularyTable,
                           generateVocabTable = generateVocabTable
                           )

}


#' @export
#'
#'
getHemoncIngredients <- function(
  connection,
  cdmDatabaseSchema,
  keepSteroids = FALSE

) {
  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "FetchDrugConceptIds.sql",
    packageName = getThisPackageName(),
    cdmDatabaseSchema = cdmDatabaseSchema,
    commentSteroids = ifelse(keepSteroids, '', '--')
  )
  DatabaseConnector::querySql(
    connection,
    sql = sql
    )$CONCEPT_ID_2
  }
