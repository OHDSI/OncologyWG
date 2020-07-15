create_regimens <- function(connectionDetails, cdmDatabaseSchema, cdmResultSchema,  writeDatabaseSchema, cohortTable = "cancer_cohort", regimenTable = "cancer_regimens", regimenIngredientTable = "cancer_regimen_ingredients", vocabularyTable = "regimen_voc_upd", drug_classification_id_input, date_lag_input, regimen_repeats = 5, cohortDefinitionId, generateVocabTable = F){
  
  connection <-  DatabaseConnector::connect(connectionDetails)
  
  sql <- SqlRender::render(SqlRender::readSql("SQL/CohortBuild.sql"), cdmDatabaseSchema = cdmDatabaseSchema, cdmResultSchema = cdmResultSchema, writeDatabaseSchema = writeDatabaseSchema, cohortTable = cohortTable, regimenTable = regimenTable, drug_classification_id_input = drug_classification_id_input, cohortDefinitionId = cohortDefinitionId) 
  #sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)
  
  DatabaseConnector::executeSql(connection, sql)
  
  sql <- SqlRender::render(SqlRender::readSql("SQL/RegimenCalc2.sql"), writeDatabaseSchema = writeDatabaseSchema, regimenTable = regimenTable, date_lag_input = date_lag_input) 
  #sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)
  
 
  for(i in c(1:regimen_repeats)){DatabaseConnector::executeSql(connection, sql)}
  
  if(generateVocabTable){
    
    sql <- SqlRender::render(SqlRender::readSql("SQL/RegimenVoc.sql"), writeDatabaseSchema = writeDatabaseSchema, cdmDatabaseSchema = cdmDatabaseSchema, vocabularyTable = vocabularyTable)
    #sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)
    DatabaseConnector::executeSql(connection, sql)
    
    }
  
  sql <- SqlRender::render(SqlRender::readSql("SQL/RegimenFormat.sql"), writeDatabaseSchema = writeDatabaseSchema, cohortTable = cohortTable, regimenTable = regimenTable, regimenIngredientTable = regimenIngredientTable, vocabularyTable = vocabularyTable) 
  #sql <- SqlRender::translate(sql,targetDialect = connectionDetails$dbms)
  
  DatabaseConnector::executeSql(connection, sql)
  
  
}
