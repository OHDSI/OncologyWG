#' @export
#'
#'
writeToEpisodeTable <- function(
  connection,
  writeDatabaseSchema,
  regimenIngredientTable,
  episodeTypeConceptId,
  cdmDatabaseSchema
) {

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "EpisodeTable.sql",
    packageName = getThisPackageName(),
    cancerRegimenIngredients = regimenIngredientTable,
    writeDatabaseSchema = writeDatabaseSchema,
    episodeTypeConceptId = episodeTypeConceptId,
    cdmDatabaseSchema = cdmDatabaseSchema
  )

  DatabaseConnector::executeSql(
    connection = connection,
    sql = sql
  )
}


#' @export
#'
writeToEpisodeEventTable <- function(
  connection,
  writeDatabaseSchema,
  regimenIngredientTable,
  episodeEventTableConceptId,
  cdmDatabaseSchema
) {

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "EpisodeEventTable.sql",
    packageName = getThisPackageName(),
    cancerRegimenIngredients = regimenIngredientTable,
    writeDatabaseSchema = writeDatabaseSchema,
    cdmDatabaseSchema = cdmDatabaseSchema,
    episodeEventTableConceptId = episodeEventTableConceptId
  )

  DatabaseConnector::executeSql(
    connection = connection,
    sql = sql
  )
}
