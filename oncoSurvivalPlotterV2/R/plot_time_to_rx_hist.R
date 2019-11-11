#' Plot a histogram of the time to treatment
#' @param dataframe dataframe from SQL queries
#' @param time_to_rx_col numeric variable indicating time to treatment
#' @param cohort_cols grouping variables of length 1 or greater
#' @import dplyr
#' @import ggplot2
#' @export

plot_time_to_rx_hist <-
function(dataframe, time_to_rx_col, cohort_cols) {

                time_to_rx_col <- enquo(time_to_rx_col)
                cohort_cols       <- enquo(cohort_cols)

                dataframe <-
                        dataframe %>%
                        mutate(!!time_to_rx_col := as.numeric(!!time_to_rx_col)) %>%
                        mutate(!!!cohort_cols := as.factor(!!!cohort_cols))

                meandat <- dataframe %>%
                                        dplyr::group_by(!!cohort_cols) %>%
                                        dplyr::summarise(mean_value = round(mean(!!time_to_rx_col)),
                                                         median_value = round(median(!!time_to_rx_col), 1))

                ggplot(data = dataframe, aes(x = !!time_to_rx_col, fill = !!cohort_cols)) +
                        geom_histogram(binwidth = 2, alpha = 0.6, position = "dodge") +
                        facet_grid(rows = vars(!!cohort_cols)) +
                        theme(
                                strip.background = element_blank(),
                                strip.text.y = element_blank(),
                        ) +
                        coord_cartesian(xlim = c(0,max(dataframe %>% select(!!time_to_rx_col) %>% unlist()))) +
                        geom_vline(data = meandat,aes(xintercept=mean_value),linetype="dashed", size = .5) +
                        geom_text(data = meandat, aes(x = round((mean_value)), y = max(select(dataframe, !!time_to_rx_col)), label = paste0("mean = ",mean_value), hjust = -0.2)) +
                        geom_vline(data = meandat,aes(xintercept=median_value),linetype="solid", size = .3, color = "#CC3300") +
                        geom_text(data = meandat, aes(x = median_value, y = max(select(dataframe, !!time_to_rx_col)), label = paste0("median = ",median_value), vjust = 2, hjust = -0.2)) +
                        xlab("Time To Treatment From Diagnosis (Days)") +
                        ylab("Frequency") +
                        labs(title = "Frequency of Time from Diagnosis to First Treatment") +
                        scale_fill_discrete(name = "Cohort")
        }
