con <- 0


db_open <- function(params) 
{
  con <<- DBI::dbConnect(RPostgres::Postgres(), dbname=params$dbname, port=params$port, user=params$user, password=params$password)
}
  
db_send <- function(sql) 
{
  tryCatch(
    {
      DBI::dbExecute(con, sql)
      # res = DBI::dbSendStatement(con, sql)
      # DBI::dbClearResult(res)
      return("")
    },
    error = function(e) {
      return(e$message)
    }
  )
}

db_select <- function(sql)
{
  tryCatch(
    {
      res <<- DBI::dbGetQuery(con, sql)
      return(res)
    },
    error = function(e) {
      res <<- "error in function!"
      return(NULL)
    }
  )
}

db_close <- function()
{
  tryCatch(
    {
      if (DBI::dbIsValid(con))
        DBI::dbDisconnect(con)
    },
    error = function(e) {
      return()
    }
  )
}

if (!exists("sql_send") || !is.function(sql_send))
  sql_send <- db_send

if (!exists("sql_select") || !is.function(sql_select))
  sql_select <- db_select

if (!exists("sql_exit") || !is.function(sql_exit))
  sql_exit <- db_close
