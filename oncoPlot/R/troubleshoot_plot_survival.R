library(DatabaseConnector)
library(dplyr)
library(ggplot2)
library(survminer)
library(survival)
source("R/try_catch_error_as_na.R")

dbms <- "" #Input one of c("oracle","postgresql","redshift","sql server","pdw", "netezza","bigquery","sqlite")
user <- ""
password <- ""
server <- ""
port = NULL
schema = NULL

##Line by Line
##1
        con_details <-
                DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                           user = user,
                                                           password = password,
                                                           server = server,
                                                           port = port,
                                                           schema = schema)
#2
        con <- DatabaseConnector::connect(connectionDetails = con_details)

#3
        rendered_sql <-
                SqlRender::loadRenderTranslateSql(sqlFilename = "time_dx_to_survival.sql",
                                                  packageName = "oncoPlot",
                                                  dbms = dbms,
                                                  cdmSchema = schema)

#4
        dataframe <- DatabaseConnector::dbGetQuery(con, statement = rendered_sql)

#5
        DatabaseConnector::dbDisconnect(conn = con)

#6
        dataframe$survival_time_col <- as.numeric(dataframe$survival_time_col)
        dataframe$event_col <- as.numeric(dataframe$event_col)
        dataframe$cohort_cols <- as.factor(dataframe$cohort_cols)

#7

        survival_object <- try_catch_error_as_na(survival::Surv(time = dataframe$survival_time_col,
                                                                 event = dataframe$event_col,
                                                                 type = "right"))

#8
                km_fit_01 <- try_catch_error_as_na(survival::survfit(survival_object ~ cohort_cols,
                                                                     data = dataframe))

#9
                        medsurv <- survminer::surv_median(km_fit_01)

#10
                        OUTPUT <- survminer::ggsurvplot(km_fit_01,
                                                        data = dataframe,
                                                        xscale = 12,
                                                        break.x.by = 6,
                                                        legend = c(0.8, 0.9),
                                                        surv.median.line = "hv",
                                                        legend.title = "Cohort",
                                                        legend.labs = levels(dataframe %>%
                                                                                     select(cohort_cols) %>% unlist())) + ggplot2::xlab("Survival Time (Years)") + ggplot2::ylab("Survival Probability") + ggplot2::ggtitle("Kaplan-Meier Curves")

#11
                        OUTPUT$plot + ggplot2::annotate("text",
                                                        x = medsurv$median + 2,
                                                        y = (1:nrow(medsurv))/20,
                                                        label = round(medsurv$median/12, 2),
                                                        parse = TRUE)


