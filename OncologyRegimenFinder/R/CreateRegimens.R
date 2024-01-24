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
#' @param useHemoncToPullDrugs Boolean parameter if TRUE algorithm will use HemOnc vocabulary as a source of ingredients otherwise - internal csv
#' @param writeToEpisodeTable Boolean parameter if TRUE algorithm will delete form episode table with `episodeTypeConceptId` and insert `regimenIngredientTable` rows with `episodeTypeConceptId`
#' @param writeToEpisodeEventTable Boolean parameter if TRUE algorithm will delete form episode_event table with `episodeEventTableConceptId` and insert `regimenIngredientTable` rows with `episodeEventTableConceptId`
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
                           useHemoncToPullDrugs = FALSE,
                           writeToEpisodeTable = FALSE,
                           writeToEpisodeEventTable = FALSE,
                           episodeTypeConceptId = 32545,
                           episodeEventTableConceptId = 1147094
                           ) {




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
  if(writeToEpisodeTable) {
    writeToEpisodeTable(
      connection = connection,
      writeDatabaseSchema = writeDatabaseSchema,
      regimenIngredientTable = regimenIngredientTable,
      episodeTypeConceptId = episodeTypeConceptId,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  }

  if(writeToEpisodeEventTable) {
    writeToEpisodeEventTable(
      connection = connection,
      writeDatabaseSchema = writeDatabaseSchema,
      regimenIngredientTable = regimenIngredientTable,
      episodeEventTableConceptId = episodeEventTableConceptId,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  }


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
