source('plot_functions.R')

TEST_DATA <- readRDS("r_survival/test_data.RData")
plot_survival(native_dataframe  = TEST_DATA,
              survival_time_col = survival_time_months,
              event_col         = event_occurred,
              cohort_col        = cohort_definition)


plot_time_to_rx_hist(native_dataframe = TEST_DATA, 
                     target_value_col = dx_to_rx_time_days, 
                     cohort_col = cohort_definition)
