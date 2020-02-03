#' Function to plot survival curve
#' @param dbms DBMS runnong on the OMOP server
#' @param survival_time_col numberic variable that indicates survival time
#' @param event_col boolean variable that indicates event occurrence
#' @param cohort_cols variable names of length 1 or greater that indicates grouping variables for output
#' @param pval TRUE if pval is to be included in the plot
#' @param median_survival_time TRUE if median survival time should be returned
#' @import DatabaseConnector
#' @import dplyr
#' @import ggplot2
#' @import survminer
#' @import survival
#' @importFrom crayon red
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

        survival_object <- try_catch_error_as_na(survival::Surv(time = dataframe$survival_time_col,
                                                       event = dataframe$event_col,
                                                       type = "right"))

        if (is.vector(survival_object)) {
                cat(crayon::red("\n\tError: survival_time and/or event_occurred not in correct format. Please check and try again.\n"))
        } else {
                km_fit_01 <- try_catch_error_as_na(survival::survfit(survival_object ~ cohort_cols,
                                                           data = dataframe))
                if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                        cat(crayon::red("\n\tError: cohort_object and/or dataframe not in correct format. Please check and try again.\n"))

                } else {
                        medsurv <- survminer::surv_median(km_fit_01)

                        OUTPUT <- survminer::ggsurvplot(km_fit_01,
                                             data = dataframe,
                                             pval = pval,
                                             xscale = 12,
                                             break.x.by = 6,
                                             legend = c(0.8, 0.9),
                                             surv.median.line = "hv",
                                             legend.title = "Cohort",
                                             legend.labs = levels(dataframe %>%
                                                                          select(cohort_cols) %>% unlist())) + xlab("Survival Time (Years)") + ylab("Survival Probability") + ggtitle("Kaplan-Meier Curves")

                        OUTPUT$plot + ggplot2::annotate("text",
                                                        x = medsurv$median + 2,
                                                        y = (1:nrow(medsurv))/20,
                                                        label = round(medsurv$median/12, 2),
                                                        parse = TRUE)
                }

        }
}


