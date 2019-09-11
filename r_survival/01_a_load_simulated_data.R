##
##
##

source("./r_survival/simdata_functions.R")
if (!(exists("DATA_00"))) {
        if (!(file.exists(input_data_fn))) {
                DATA_00 <-
                        simulate_survival_data(seed = seed, obs_count = 500) %>%
                        mutate(smoking_status = as.factor(sample_from_control_list(seed = seed, 500, c("1", "0")))) %>%
                        mutate(cancer_history = as.factor(sample_from_control_list(seed = (seed + sample(1:10, 1)), 500, c("1", "0"))))
                
                write.csv(DATA_00, input_data_fn, row.names = FALSE)
        } else {
                DATA_00 <-
                        read.csv(input_data_fn) %>%
                                        call_mr_clean()
        }
}
