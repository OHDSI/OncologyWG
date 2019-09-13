
plot_survival <-
        function(native_dataframe, survival_time_col, event_col, cohort_col) {
                source("utils.R")
                invisible(load_packages())
                survival_time_col <- enquo(survival_time_col)
                event_col         <- enquo(event_col)
                cohort_col        <- enquo(cohort_col)
                
                native_dataframe <- 
                        native_dataframe %>%
                        rename(cohort_definition = !!cohort_col)
                
                native_dataframe <-
                        native_dataframe %>%
                        mutate_at(vars(!!survival_time_col, !!event_col), as.numeric) %>%
                        mutate(cohort_definition = as.factor(cohort_definition))
                
                survival_object <<- try_catch_error_as_na(Surv(time  = native_dataframe %>% select(!!survival_time_col) %>% unlist(),
                                                        event = native_dataframe %>% select(!!event_col) %>% unlist()))
                
                if ((length(survival_object) == 1) & is.na(survival_object[1])) {
                        cat("\n\tERROR: survival_time and/or event_occurred not in correct format. Please check and try again.")
                } else {
                        km_fit_01 <- try_catch_error_as_na(survfit(survival_object ~ cohort_definition, data = native_dataframe))
                        if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                                cat("\n\tERROR: cohort_object and/or native_dataframe not in correct format. Please check and try again.")
                        } else {
                                ggsurvplot(km_fit_01, data = native_dataframe,
                                           legend.title = "Cohort",
                                           legend.labs = levels(native_dataframe %>%
                                                                        select(!!cohort_col) %>%
                                                                        unlist())) +
                                        xlab("Survival Time (Months)") +
                                        ylab("Survival Probability") +
                                        ggtitle("Kaplan-Meier Curves By Cohort")
                        }
                }
                
        }

return_median_survival_time <-
        function(native_dataframe, survival_time_col, event_col, cohort_col) {
                source("utils.R")
                invisible(load_packages())
                survival_time_col <- enquo(survival_time_col)
                event_col         <- enquo(event_col)
                cohort_col        <- enquo(cohort_col)
                
                native_dataframe <- 
                        native_dataframe %>%
                        rename(cohort_definition = !!cohort_col)
                
                native_dataframe <-
                        native_dataframe %>%
                        mutate_at(vars(!!survival_time_col, !!event_col), as.numeric) %>%
                        mutate(cohort_definition = as.factor(cohort_definition))
                
                survival_object <- try_catch_error_as_na(Surv(time  = native_dataframe %>% select(!!survival_time_col) %>% unlist(),
                                                              event = native_dataframe %>% select(!!event_col) %>% unlist()))
                
                if ((length(survival_object) == 1) & is.na(survival_object[1])) {
                        cat("\n\tERROR: survival_time and/or event_occurred not in correct format. Please check and try again.")
                } else {
                        km_fit_01 <- try_catch_error_as_na(survfit(survival_object ~ cohort_definition, data = native_dataframe))
                        if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                                cat("\n\tERROR: cohort_object and/or native_dataframe not in correct format. Please check and try again.")
                        } else {
                                return(surv_median(km_fit_01))
                        }
                }
        }

return_pval_survival_time <-
        function(native_dataframe, survival_time_col, event_col, cohort_col) {
                source("utils.R")
                invisible(load_packages())
                survival_time_col <- enquo(survival_time_col)
                event_col         <- enquo(event_col)
                cohort_col        <- enquo(cohort_col)
                
                native_dataframe <- 
                        native_dataframe %>%
                        rename(cohort_definition = !!cohort_col)
                
                native_dataframe <-
                        native_dataframe %>%
                        mutate_at(vars(!!survival_time_col, !!event_col), as.numeric) %>%
                        mutate(cohort_definition = as.factor(cohort_definition))
                
                survival_object <- try_catch_error_as_na(Surv(time  = native_dataframe %>% select(!!survival_time_col) %>% unlist(),
                                                              event = native_dataframe %>% select(!!event_col) %>% unlist()))
                
                if ((length(survival_object) == 1) & is.na(survival_object[1])) {
                        cat("\n\tERROR: survival_time and/or event_occurred not in correct format. Please check and try again.")
                } else {
                        km_fit_01 <- try_catch_error_as_na(survfit(survival_object ~ cohort_definition, data = native_dataframe))
                        if ((length(km_fit_01) == 1) & any(is.na(km_fit_01))) {
                                cat("\n\tERROR: cohort_object and/or native_dataframe not in correct format. Please check and try again.")
                        } else {
                                return(surv_pvalue(km_fit_01))
                        }
                }
        }

plot_time_to_rx_hist <-
        function(native_dataframe, target_value_col, cohort_col) {
                source("utils.R")
                invisible(load_packages())
                
                target_value_col <- enquo(target_value_col)
                cohort_col       <- enquo(cohort_col)
                
                native_dataframe <-
                        native_dataframe %>%
                        mutate(!!target_value_col := as.numeric(!!target_value_col)) %>%
                        mutate(!!cohort_col := as.factor(!!cohort_col))
                
                meandat <- group_by(native_dataframe, !!cohort_col) %>% summarize(mean_value = round(mean(!!target_value_col), 1))
                
                ggplot(data = native_dataframe, aes(x = !!target_value_col, fill = !!cohort_col)) +
                        geom_histogram(binwidth = 2, alpha = 0.6, position = "dodge") +
                        facet_grid(rows = vars(!!cohort_col)) +
                        theme(
                                strip.background = element_blank(),
                                strip.text.y = element_blank(),
                        ) +
                        coord_cartesian(xlim = c(0,max(native_dataframe %>% select(!!target_value_col) %>% unlist()))) +
                        geom_vline(data = meandat,
                                   aes(xintercept=mean_value, color = !!cohort_col),
                                   linetype="dashed", size = .5) +
                        geom_text(data = meandat, aes(x = round(mean_value, 3), y = 35, label = paste0("mean = ",mean_value), hjust = -.1)) +
                        xlab("Time To Treatment From Diagnosis (Days)") +
                        ylab("Frequency")
        }

