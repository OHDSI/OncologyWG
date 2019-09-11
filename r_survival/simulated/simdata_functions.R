sample_from_control_list <-
        function(seed, sample_count, control_vector, replace = TRUE) {
                set.seed(seed = seed)
                
                indices <- sample(1:length(control_vector), sample_count, replace = replace)
                
                x <- vector()
                for (i in 1:length(indices)) {
                        x[i] <- control_vector[indices[i]]
                }
                return(x)
        }


simulate_survival_data <- 
        function(seed, obs_count) {
                set.seed(seed = seed)
                patient_id        <-  as.character(1:obs_count)
                survival_time_months     <-  rnorm(obs_count, mean = 24, sd = 6)
                dx_to_rx_time_days       <-  as.integer(rnorm(obs_count, mean = 30, sd = 10))
                event_occurred    <-  sample(0:1, obs_count, replace = TRUE)
                cohort_definition <-  sample_from_control_list(seed = seed,
                                                               sample_count = obs_count,
                                                               control_vector = c("metastatic", "nonmetastatic", "unknown"))
                
                return(data.frame(patient_id            = patient_id,
                                  survival_time_months  = as.double(survival_time_months),
                                  dx_to_rx_time_days    = as.double(dx_to_rx_time_days),
                                  event_occurred        = as.double(event_occurred),
                                  cohort_definition     = as.factor(cohort_definition)
                                  )
                )
        }

generate_sim_data <-
        function(new_data_obj_name = "DATA_00", obs_count = 1000) {
                if (!(exists(new_data_obj_name))) {
                        TEMP_FN <- paste0("./r_survival/simulated/", new_data_obj_name, ".RData")
                        if (!(file.exists(TEMP_FN))) {
                                seed <- sample(1:1000, 1)
                                assign(new_data_obj_name, simulate_survival_data(seed = seed, obs_count = obs_count), envir = globalenv())
                                saveRDS(get(new_data_obj_name), TEMP_FN)
                        } else {
                                require(tidyverse)
                                DATA_00 <<-
                                        readr::read_rds(TEMP_FN)
                        }
                }
        }
