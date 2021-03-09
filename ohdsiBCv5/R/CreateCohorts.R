# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of ohdsiBCnew
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.createCohorts <- function(connection,
                           cdmDatabaseSchema,
                           vocabularyDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema,
                           cohortTable,
                           oracleTempSchema,
                           outputFolder) {
  
  # Create study cohort table structure:
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CreateCohortTable.sql",
                                           packageName = "ohdsiBCnew",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  
  
  # Insert rule names in cohort_inclusion table:
  pathToCsv <- system.file("cohorts", "InclusionRules.csv", package = "ohdsiBCnew")
  inclusionRules <- readr::read_csv(pathToCsv, col_types = readr::cols()) 
  inclusionRules <- data.frame(cohort_definition_id = inclusionRules$cohortId,
                               rule_sequence = inclusionRules$ruleSequence,
                               name = inclusionRules$ruleName)
  DatabaseConnector::insertTable(connection = connection,
                                 tableName = "#cohort_inclusion",
                                 data = inclusionRules,
                                 dropTableIfExists = FALSE,
                                 createTable = FALSE,
                                 tempTable = TRUE,
                                 oracleTempSchema = oracleTempSchema)
  
  
  # Instantiate cohorts:
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "ohdsiBCnew")
  cohortsToCreate <- readr::read_csv(pathToCsv, col_types = readr::cols())
  for (i in 1:nrow(cohortsToCreate)) {
    writeLines(paste("Creating cohort:", cohortsToCreate$name[i]))
    sql <- SqlRender::loadRenderTranslateSql(sqlFilename = paste0(cohortsToCreate$name[i], ".sql"),
                                             packageName = "ohdsiBCnew",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cdm_database_schema = cdmDatabaseSchema,
                                             vocabulary_database_schema = vocabularyDatabaseSchema,
                                             
                                             results_database_schema.cohort_inclusion = "#cohort_inclusion",  
                                             results_database_schema.cohort_inclusion_result = "#cohort_inc_result",  
                                             results_database_schema.cohort_inclusion_stats = "#cohort_inc_stats",  
                                             results_database_schema.cohort_summary_stats = "#cohort_summary_stats",  
                                                
                                             target_database_schema = cohortDatabaseSchema,
                                             target_cohort_table = cohortTable,
                                             target_cohort_id = cohortsToCreate$cohortId[i])
    DatabaseConnector::executeSql(connection, sql)
  }
  
  # Fetch cohort counts:
  sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @cohort_database_schema.@cohort_table GROUP BY cohort_definition_id"
  sql <- SqlRender::render(sql,
                           cohort_database_schema = cohortDatabaseSchema,
                           cohort_table = cohortTable)
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  counts <- DatabaseConnector::querySql(connection, sql)
  names(counts) <- SqlRender::snakeCaseToCamelCase(names(counts))
  counts <- merge(counts, data.frame(cohortDefinitionId = cohortsToCreate$cohortId,
                                     cohortName  = cohortsToCreate$name))
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"))
  
  
  # Fetch inclusion rule stats and drop tables:
  fetchStats <- function(tableName) {
    sql <- "SELECT * FROM #@table_name"
    sql <- SqlRender::render(sql, table_name = tableName)
    sql <- SqlRender::translate(sql = sql, 
                                targetDialect = attr(connection, "dbms"),
                                oracleTempSchema = oracleTempSchema)
    stats <- DatabaseConnector::querySql(connection, sql)
    names(stats) <- SqlRender::snakeCaseToCamelCase(names(stats))
    fileName <- file.path(outputFolder, paste0(SqlRender::snakeCaseToCamelCase(tableName), ".csv"))
    write.csv(stats, fileName, row.names = FALSE)
    
    sql <- "TRUNCATE TABLE #@table_name; DROP TABLE #@table_name;"
    sql <- SqlRender::render(sql, table_name = tableName)
    sql <- SqlRender::translate(sql = sql, 
                                targetDialect = attr(connection, "dbms"),
                                oracleTempSchema = oracleTempSchema)
    DatabaseConnector::executeSql(connection, sql)
  }
  fetchStats("cohort_inclusion")
  fetchStats("cohort_inc_result")
  fetchStats("cohort_inc_stats")
  fetchStats("cohort_summary_stats")
  
}

