source('plot_functions.R')

return_median_survival_time(native_dataframe = TEST_DATA,
                            survival_time_col = survival_time_months,
                            event_col = event_occurred,
                            cohort_col = cohort_definition)

return_pval_survival_time(native_dataframe = TEST_DATA,
                          survival_time_col = survival_time_months,
                          event_col = event_occurred,
                          cohort_col = cohort_definition)
