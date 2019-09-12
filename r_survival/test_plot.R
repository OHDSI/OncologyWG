source('G:/GitHub/OncologyWG/r_survival/plot_functions.R')

TEST_DATA <- readRDS("./r_survival/test_data.RData")
plot_survival(native_dataframe = DATA_00,
              survival_time_col = survival_time_months,
              event_col = event_occurred,
              cohort_col = cohort_definition)

plot_time_to_rx_hist(native_dataframe = DATA_00, 
                     target_value_col = dx_to_rx_time_days, 
                     cohort_col = cohort_definition)
