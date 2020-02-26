#' Plot a Time-to-Treatment Histogram
#' @param dbms one of the following supported Database Management Systems: c("oracle","postgresql","redshift","sql server","pdw", "netezza","bigquery","sqlite")
#' @param user username for OMOP v5.0 instance
#' @param password password for OMOP v5.0 instance
#' @param server OMOP v5.0 server
#' @param port NULL by default.
#' @param schema NULL by default.
#' @import dplyr
#' @import ggplot2
#' @import DatabaseConnector
#' @export

plot_time_to_rx_hist <-
function(dbms = c("oracle","postgresql","redshift","sql server","pdw", "netezza","bigquery","sqlite"), user, password, server, port = NULL, schema = NULL) {

                con_details <-
                        DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                   user = user,
                                                                   password = password,
                                                                   server = server,
                                                                   port = port,
                                                                   schema = schema)

                con <- DatabaseConnector::connect(connectionDetails = con_details)

                rendered_sql <-
                        SqlRender::loadRenderTranslateSql(sqlFilename = "time_dx_to_rx.sql",
                                                          packageName = "oncoPlot",
                                                          dbms = dbms,
                                                          cdmSchema = schema)

                dataframe <- DatabaseConnector::dbGetQuery(con, statement = rendered_sql)

                DatabaseConnector::dbDisconnect(conn = con)

                dataframe$time_to_rx_col <- as.numeric(dataframe$time_to_rx_col)
                dataframe$cohort_cols <- as.factor(dataframe$cohort_cols)

                meandat <- dataframe %>%
                                        dplyr::group_by(cohort_cols) %>%
                                        dplyr::summarise(mean_value = round(mean(time_to_rx_col)),
                                                         median_value = round(median(time_to_rx_col), 1))

                ggplot(data = dataframe, aes(x = time_to_rx_col, fill = cohort_cols)) +
                        geom_histogram(binwidth = 2, alpha = 0.6, position = "dodge") +
                        facet_grid(rows = vars(cohort_cols)) +
                        theme(
                                strip.background = element_blank(),
                                strip.text.y = element_blank(),
                        ) +
                        coord_cartesian(xlim = c(0,max(dataframe %>% select(time_to_rx_col) %>% unlist()))) +
                        geom_vline(data = meandat,aes(xintercept=mean_value),linetype="dashed", size = .5) +
                        geom_text(data = meandat, aes(x = round((mean_value)), y = max(select(dataframe, time_to_rx_col)), label = paste0("mean = ",mean_value), hjust = -0.2)) +
                        geom_vline(data = meandat,aes(xintercept=median_value),linetype="solid", size = .3, color = "#CC3300") +
                        geom_text(data = meandat, aes(x = median_value, y = max(select(dataframe, time_to_rx_col)), label = paste0("median = ",median_value), vjust = 2, hjust = -0.2)) +
                        xlab("Time To Treatment From Diagnosis (Days)") +
                        ylab("Frequency") +
                        labs(title = "Frequency of Time from Diagnosis to First Treatment") +
                        scale_fill_discrete(name = "Cohort")
        }
