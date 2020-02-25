#' Plot a Kaplan-Meier Curve
#' @param dbms one of the following supported Database Management Systems: c("oracle","postgresql","redshift","sql server","pdw", "netezza","bigquery","sqlite")
#' @param user username for OMOP v5.0 instance
#' @param password password for OMOP v5.0 instance
#' @param server OMOP v5.0 server
#' @param port NULL by default.
#' @param schema NULL by default.
#' @import DatabaseConnector
#' @import dplyr
#' @import ggplot2
#' @import survminer
#' @import survival
#' @export
#'
#'

plot_survival <- function(dbms = c("oracle","postgresql","redshift","sql server","pdw", "netezza","bigquery","sqlite"), user, password, server, port = NULL, schema = NULL) {

        con_details <-
        DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                   user = user,
                                                   password = password,
                                                   server = server,
                                                   port = port,
                                                   schema = schema)

        con <- DatabaseConnector::connect(connectionDetails = con_details)

        rendered_sql <-
                SqlRender::loadRenderTranslateSql(sqlFilename = "time_dx_to_survival.sql",
                                                  packageName = "oncoPlot",
                                                  dbms = dbms,
                                                  cdmSchema = schema)

        dataframe <- DatabaseConnector::dbGetQuery(con, statement = rendered_sql)

        DatabaseConnector::dbDisconnect(conn = con)

        dataframe$survival_time_col <- as.numeric(dataframe$survival_time_col)
        dataframe$event_col <- as.numeric(dataframe$event_col)

        dataframe$cohort_cols <- as.factor(dataframe$cohort_cols)

        survival_object <<- try_catch_error_as_na(survival::Surv(time = dataframe$survival_time_col,
                                                       event = dataframe$event_col,
                                                       type = "right"))

        if (is.vector(survival_object)) {
                cat("\n\tError: survival_time and/or event_occurred not in correct format. Please check and try again.\n")
        } else {
                km_fit_01 <- try_catch_error_as_na(survival::survfit(survival_object ~ cohort_cols,
                                                           data = dataframe))
                if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                        cat("\n\tError: cohort_object and/or dataframe not in correct format. Please check and try again.\n")

                } else {
                        medsurv <- survminer::surv_median(km_fit_01)

                        OUTPUT <- survminer::ggsurvplot(km_fit_01,
                                             data = dataframe,
                                             xscale = 12,
                                             break.x.by = 6,
                                             legend = c(0.8, 0.9),
                                             surv.median.line = "hv",
                                             legend.title = "Cohort",
                                             legend.labs = levels(dataframe %>%
                                                                          select(cohort_cols) %>% unlist())) + ggplot2::xlab("Survival Time (Years)") + ggplot2::ylab("Survival Probability") + ggplot2::ggtitle("Kaplan-Meier Curves")

                        OUTPUT$plot + ggplot2::annotate("text",
                                                        x = medsurv$median + 2,
                                                        y = (1:nrow(medsurv))/20,
                                                        label = round(medsurv$median/12, 2),
                                                        parse = TRUE)
                }

        }
}


