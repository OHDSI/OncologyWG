readDbSql <- function(sql_filename, dbms) {
  supported_dbms <- c("postgresql", "redshift", "sqlite", "bigquery")
  if(!(dbms %in% supported_dbms)) {
    stop(paste(dbms, "is not a supported database. \nSupported dbms are", paste(supported_dbms, collapse = ", "), "."))
  }
  package <- getThisPackageName()
  path <- system.file("sql", dbms, sql_filename, package = package, mustWork = TRUE)
  SqlRender::readSql(path)
}

getThisPackageName <- function() {
  return("OncologyRegimenFinder")
}

getIngredientsIdsWithSteroids <- function(){
  path <- system.file("csv",
                      sql_filename = "distIdsWithoutSupportiveWithSteroids.csv",
                      package = getThisPackageName(),
                      mustWork = TRUE)
  read.csv(path)$x
}

getIngredientsIdsWithoutSteroids <- function(){
  path <- system.file("csv",
                      sql_filename = "distIdsWithoutSupportiveAndSteroids.csv",
                      package = getThisPackageName(),
                      mustWork = TRUE)
  read.csv(path)$x
}


