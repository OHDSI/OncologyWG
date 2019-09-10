
#Creating survival object
#
survival_object <- Surv(time  = survival_time,
                        event = event_occurred)
print(survival_object)


#Fitting Kaplan-Meier curves to survival object
#
km_fit_01 <- survfit(survival_object ~ cohort_definition, data = DATA_00)
summary(km_fit_01)

#Plotting the survival curve
#

ggsurvplot(km_fit_01, data = DATA_00, pval = TRUE)



#Fitting Cox PH Model
#
cph_fit_02 <- coxph(survival_object ~ smoking_status + cancer_history, data = DATA_00)

#Plotting Cox ph model
ggforest(cph_fit_02, data = DATA_00)
