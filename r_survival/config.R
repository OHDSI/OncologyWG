# PACKAGES
required_packages <- c("tidyverse","lubridate","openxlsx", "survival", "survminer")
seed <- 13519
# INPUT DATA
input_data_fn <- "DATA_00.csv"

# INPUT DATA Fields that need to be dichomtomized
cont_field <- ""

## Creating survival object
# INPUT DATA Field that provides survival time
survival_time <- DATA_00$survival_time
survival_time <- as.double(survival_time)

# INPUT DATA Field that tells us if the event occurred or not
event_occurred <- DATA_00$event_occurred
event_occurred <- as.double(event_occurred)

# COHORT variable: variable that stratifies the output into cohorts
# 
cohort_definition <- DATA_00$cohort_definition


#COX Proportional Hazards covariates
coxph_covariates <- c("smoking_status", "cancer_history")
