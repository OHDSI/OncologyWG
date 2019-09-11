simulate_survival_data <- 
        function(seed, obs_count) {
                set.seed(seed = seed)
                patient_id        <-  as.character(1:obs_count)
                cancer_type       <-  c("breast")
                survival_time     <-  rnorm(obs_count, mean = 365, sd = 100)
                event_occurred    <-  sample(0:1, obs_count, replace = TRUE)
                cohort_definition <-  sample(0:1, obs_count, replace = TRUE)
                
                return(data.frame(patient_id     = patient_id,
                                  survival_time  = as.double(survival_time),
                                  event_occurred = as.double(event_occurred),
                                  cohort_definition = as.factor(cohort_definition))
                )
        }

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
