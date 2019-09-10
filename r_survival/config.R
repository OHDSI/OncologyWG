# PACKAGES
required_packages <- c("tidyverse","lubridate","openxlsx", "survival", "survminer")

# INPUT DATA
input_data_fn <- ""

# INPUT DATA Fields that need to be dichomtomized
cont_field <- ""

## Creating survival object
# INPUT DATA Field that provides survival time
survival_time <- ""
survival_time <- as.double(survival_time)

# INPUT DATA Field that tells us if the event occurred or not
event_occurred <- ""
survival_time <- as.double(event_occurred)

# COHORT variable: variable that stratifies the output into cohorts
# 
cohort_definition <- ""


#COX Proportional Hazards covariates
coxph_covariates <- c("")
