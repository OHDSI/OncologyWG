
#Creating survival object
#
survival_object <- Surv(time  = survival_time,
                        event = event_occurred)
print(survival_object)


#Fitting Kaplan-Meier curves to survival object
#
km_fit_01 <- survfit(survival_object ~ cohort_definition, data = data_xx_)
summary(km_fit_01)

#Plotting the survival curve
#

ggsurvplot(km_fit_01, data = data_xx_, pval = TRUE)



#Fitting Cox PH Model
#
cph_fit_02 <- coxph(survival_object ~ paste(cox_covariates, collapse = " + "), data = data_xx_)

#Plotting Cox ph model
ggforest(fit.coxph, data = data_xx_)