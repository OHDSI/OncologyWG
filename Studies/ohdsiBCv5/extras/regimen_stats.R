###########################################################
########################## DATA PULL
sql <- SqlRender::renderSql(
  "SELECT DISTINCT cohort_definition_id, year(cohort_start_date) - year_of_birth as age
  FROM @cohortDatabaseSchema.@cohortTable c
  LEFT JOIN @cdmDatabaseSchema.person p on c.subject_id = p.person_id
  ",
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  cdmDatabaseSchema = cdmDatabaseSchema)


sql <- SqlRender::translateSql(sql$sql, targetDialect = connectionDetails$dbms)

ages <- DatabaseConnector::dbGetQuery(DatabaseConnector::connect(connectionDetails),
                                                    sql$sql) %>%
  group_by(cohort_definition_id) %>%
  summarise(lq_age= quantile(age, 0.25,na.rm = T),
            med_age = quantile(age, 0.5, na.rm = T),
            uq_age = quantile(age, 0.75, na.rm = T),
            mean_age = mean(age, na.rm=T))


###########################################################
sql <- SqlRender::renderSql(
  "SELECT DISTINCT c.cohort_definition_id, c.subject_id, c.cohort_start_date, c.cohort_end_date,
       op.observation_period_start_date, op.observation_period_end_date, d.death_date, concept.concept_name as gender, p.year_of_birth,
       r.*, (case when regimen in ('pembrolizumab','nivolumab') then 'Anti-PD-1 mono'
									when regimen like ('%pembrolizumab%') then 'Anti-PD-1 combo'
									when regimen like ('%nivolumab%') then 'Anti-PD-1 combo'
									when regimen = 'cisplatin,doxorubicin,methotrexate,vinblastine' then 'MVAC'
									when regimen = 'cisplatin,gemcitabine' then 'Cisplatin + gemcitabine'
									when regimen  like ('%cisplatin%') then 'Other cisplatin'
									when regimen = 'carboplatin,gemcitabine' then 'Carboplatin + gemcitabine'
									when regimen like ('%carboplatin%') then 'Other carboplatin'
									when regimen = 'paclitaxel' then 'Paclitaxel mono'
									when regimen = 'gemcitabine' then 'Gemcitabine mono'
									else 'Other' end) as categorized_regimen
FROM @cohortDatabaseSchema.@cohortTable c
LEFT JOIN @cohortDatabaseSchema.@regimenIngredientsTable r 
  on r.person_id = c.subject_id 
  and r.regimen_start_date >= DATEADD(day, -14, c.cohort_start_date)
  and r.regimen_end_date >= c.cohort_start_date
  and r.regimen_start_date <= c.cohort_end_date
LEFT JOIN @cdmDatabaseSchema.observation_period op
  on op.person_id = c.subject_id
  and op.observation_period_start_date <= c.cohort_start_date
  and op.observation_period_end_date >= c.cohort_end_date
LEFT JOIN @cdmDatabaseSchema.@deathTable d on d.person_id = c.subject_id
LEFT JOIN @cdmDatabaseSchema.person p on c.subject_id = p.person_id
LEFT JOIN @cdmDatabaseSchema.concept on concept.concept_id = p.gender_concept_id
ORDER BY c.cohort_definition_id, c.subject_id, r.regimen_start_date
",
  cohortDatabaseSchema = cohortDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  regimenIngredientsTable = regimenIngredientsTable,
  cohortTable = cohortTable,
  deathTable = deathTable)

sql <- SqlRender::translateSql(sql$sql, targetDialect = connectionDetails$dbms)

formatted_regimens <- DatabaseConnector::dbGetQuery(DatabaseConnector::connect(connectionDetails),
                                                    sql$sql)

formatted_regimens <- formatted_regimens %>%
  left_join(read_csv("inst/settings/CohortsToCreate.csv") %>%
              select(cohort_definition_id = cohortId, popn = atlasName)) %>%
  mutate(popn = str_remove(popn, " \\(.*")) %>%
  group_by(cohort_definition_id, popn, subject_id, cohort_start_date, cohort_end_date, observation_period_start_date, observation_period_end_date, death_date, regimen, categorized_regimen, regimen_start_date) %>%
  summarise(regimen_end_date = max(ingredient_end_date)) %>%
  mutate(regimen_start_date = pmax(cohort_start_date, regimen_start_date)) %>%
  select(cohort_definition_id, popn, subject_id, cohort_start_date, cohort_end_date, observation_period_start_date, observation_period_end_date, death_date, regimen_start_date, regimen_end_date, regimen, categorized_regimen) %>%
  distinct %>%
  group_by(cohort_definition_id, popn, subject_id, cohort_start_date) %>%
  arrange(cohort_definition_id, popn, subject_id, cohort_start_date,regimen_start_date) %>%
  mutate(new_line = coalesce(lag(regimen,1) != regimen, TRUE),
         ordinal = cumsum(new_line)) %>%
  group_by(cohort_definition_id, popn, subject_id, cohort_start_date, cohort_end_date, observation_period_start_date, observation_period_end_date, death_date, regimen, categorized_regimen, ordinal) %>%
  summarise(regimen_start_date = min(regimen_start_date),
            regimen_end_date = max(regimen_end_date),
            treatment_year = year(regimen_start_date) )%>%
  mutate(ordinal = case_when(is.na(regimen) ~ as.integer(0), TRUE ~ ordinal)) %>%
  group_by(cohort_definition_id, subject_id) %>%
  arrange(regimen_start_date) %>%
  mutate(next_regimen_start = lead(regimen_start_date,1),
         treatment_start_date = min(regimen_start_date),
         treatment_end_date = max(regimen_end_date))

#formatted_regimens$death_date[!is.na(formatted_regimens$death_date)] <- formatted_regimens$observation_period_end_date[!is.na(formatted_regimens$death_date)] 
#formatted_regimens$death_date <- as.Date(formatted_regimens$death_date, origin = "1970-01-01")

###########################################################
########################## Characterization
###########################################################
population_summary <- purrr::map(list(`Condition Index` = sym("cohort_start_date"), `Treatment Index` = sym("treatment_start_date")),
                                 function(.x){
                                   formatted_regimens %>%
             filter(!is.na(.data[[.x]])) %>%
             group_by(popn, subject_id, cohort_end_date, treatment_start_date, cohort_start_date) %>%  
             summarise(lines_of_treatment = max(ordinal),
                       treatment_end_date =   max(case_when(is.na(regimen_end_date) ~ {{ .x }},TRUE ~ regimen_end_date)),
            #           treatment_start_date = min(case_when(is.na(regimen_start_date) ~ {{ .x }},TRUE ~ regimen_start_date))
                       ) %>%
             group_by(popn) %>%
             summarise(count_persons = n_distinct(subject_id),
                       avg_lines_of_treatment = mean(lines_of_treatment),
                       lq_lines_of_treatment = quantile(lines_of_treatment, 0.25,na.rm = T),
                       med_lines_of_treatment = quantile(lines_of_treatment, 0.5, na.rm = T),
                       uq_lines_of_treatment = quantile(lines_of_treatment, 0.75, na.rm = T),  
                       max_lines_of_treatment = quantile(lines_of_treatment, 1.00, na.rm = T),  
                       lq_follow_up = quantile(cohort_end_date - {{ .x }}, 0.25,na.rm = T),
                       med_follow_up = quantile(cohort_end_date - {{ .x }}, 0.5, na.rm = T),
                       uq_follow_up = quantile(cohort_end_date - {{ .x }}, 0.75, na.rm = T),
                       lq_follow_up_cohort = quantile(cohort_end_date - cohort_start_date, 0.25,na.rm = T),
                       med_follow_up_cohort = quantile(cohort_end_date - cohort_start_date, 0.5, na.rm = T),
                       uq_follow_up_cohort = quantile(cohort_end_date - cohort_start_date, 0.75, na.rm = T),
                       lq_treatment_duration = quantile(treatment_end_date - treatment_start_date, 0.25,na.rm = T),
                       med_treatment_duration = quantile(treatment_end_date - treatment_start_date, 0.5, na.rm = T),
                       uq_treatment_duration = quantile(treatment_end_date - treatment_start_date, 0.75, na.rm = T)) %>%
             ungroup %>%
             mutate(`Data Source` =  "Oncology EMR",
                    `Population` = popn,
                    `Patients` = scales::comma(count_persons, big.mark=","),
                    `Lines of treatment, avg` = scales::comma(avg_lines_of_treatment, accuracy = 0.01),
                    `Lines of treatment, median (IQR)` = str_c(round(med_lines_of_treatment,0), " (",round(lq_lines_of_treatment,0),"-",  round(uq_lines_of_treatment,0),")"),
                    `Lines of treatment, max` = round(max_lines_of_treatment, 0),
                    `Treatment Duration, median (IQR)` =  str_c(round(med_treatment_duration,0), " days (",round(lq_treatment_duration,0),"-",  round(uq_treatment_duration,0),")"),
                    `Follow-up from index, median (IQR)` =  str_c(round(med_follow_up,0), " days (",round(lq_follow_up,0),"-",  round(uq_follow_up,0),")"),
                    `Follow-up from diagnosis, median (IQR)` =  str_c(round(med_follow_up_cohort,0), " days (",round(lq_follow_up_cohort,0),"-",  round(uq_follow_up_cohort,0),")")) %>%
             select(`Data Source`:`Follow-up from diagnosis, median (IQR)`)}) %>%
  bind_rows(.id = "index_date")

###########################################################
########################## Lines of treatment
###########################################################  
stats_by_line <- purrr::map_df(c(1,2,3), function(therapy_line){
  
  formatted_regimens %>%
    group_by(cohort_definition_id, popn, subject_id) %>%
    arrange(regimen_start_date) %>%
    mutate(last_regimen_start = lag(regimen_start_date,1),
           last_regimen_end = lag(regimen_end_date, 1)) %>%
    ungroup %>%
    filter(ordinal == therapy_line) %>%
    group_by(cohort_definition_id,popn,ordinal) %>%
    summarise(count_persons_treated = scales::comma(n_distinct(subject_id), big.mark=","),
              lq_time_since_diagnosis = quantile(regimen_start_date - cohort_start_date, 0.25,na.rm = T),
              med_time_since_diagnosis = quantile(regimen_start_date - cohort_start_date, 0.5, na.rm = T),
              uq_time_since_diagnosis = quantile(regimen_start_date - cohort_start_date, 0.75, na.rm = T),
              lq_treatment_length = quantile(regimen_end_date - regimen_start_date, 0.25, na.rm = T),
              med_treatment_length = quantile(regimen_end_date - regimen_start_date, 0.5,na.rm = T),
              uq_treatment_length = quantile(regimen_end_date - regimen_start_date, 0.75,na.rm = T),
              lq_time_since_last_regimen_end = quantile(regimen_start_date - last_regimen_end, 0.25, na.rm = T),
              med_time_since_last_regimen_end = quantile(regimen_start_date - last_regimen_end, 0.5, na.rm = T),
              uq_time_since_last_regimen_end = quantile(regimen_start_date - last_regimen_end, 0.75, na.rm = T),
  lq_time_since_last_regimen_start = quantile(regimen_start_date - last_regimen_start, 0.25, na.rm = T),
  med_time_since_last_regimen_start = quantile(regimen_start_date - last_regimen_start, 0.5, na.rm = T),
  uq_time_since_last_regimen_start = quantile(regimen_start_date - last_regimen_start, 0.75, na.rm = T)) %>% mutate_at(vars(lq_time_since_diagnosis:uq_time_since_last_regimen_start), as.integer)
}) %>%
  ungroup %>%
  mutate(`Data Source` = "Oncology EMR",
         `Time since diagnosis, median (IQR)` = str_c(round(med_time_since_diagnosis,0), " days (", 
                                                      round(lq_time_since_diagnosis,0),"-", 
                                                      round(uq_time_since_diagnosis,0),")"),
         `Treatment line duration, median (IQR)` = str_c(round(med_treatment_length,0), " days (", 
                                                         round(lq_treatment_length,0),"-", 
                                                         round(uq_treatment_length,0),")"),
         `Time since previous line end, median (IQR)`  = str_c(round(med_time_since_last_regimen_end, 0), " days (", 
                                                           round(lq_time_since_last_regimen_end, 0),"-", 
                                                           round(uq_time_since_last_regimen_end, 0),")"),
         `Time since previous line start, median (IQR)`  = str_c(round(med_time_since_last_regimen_start, 0), " days (", 
                                                           round(lq_time_since_last_regimen_start, 0),"-", 
                                                           round(uq_time_since_last_regimen_start, 0),")")) %>%
  select(`Data Source`,`Population` = popn, `Line-of-treatment` = ordinal, `Patients` = count_persons_treated,
         `Time since diagnosis, median (IQR)`, `Time since previous line end, median (IQR)`,`Time since previous line start, median (IQR)`, `Treatment line duration, median (IQR)`)


###########################################################
########################## Regimen share
###########################################################
regimens_by_treatment_line <- purrr::map_df(unique(formatted_regimens$popn), function(popn_s){
  
  dta <- formatted_regimens %>%
    filter(popn == popn_s) %>%
    group_by(ordinal)  %>%
    mutate(count = n_distinct(subject_id)) %>%
    filter(count >= 0)
  
  if(nrow(dta) == 0){return(NULL)}
  
  dta <- purrr::map_df(list(raw_regimen = "regimen", categorized_regimen = "categorized_regimen"),    
                ~dta %>%
                  filter(ordinal >= 1 & ordinal <= 3) %>%
                  ungroup %>%
                  mutate(grouping = .x,
                         regimen = .data[[.x]]) %>%
                  group_by(grouping, ordinal, regimen) %>%
                  summarise(count = n()) %>%
                  ungroup %>%
                  mutate(population = popn_s) %>%
                  mutate(count = case_when(count <= count_mask ~ as.integer(count_mask), TRUE ~ count))
                )
  
})


yearly_regimens_by_treatment_line <- purrr::map(split(formatted_regimens, formatted_regimens$popn), function(population){
  purrr::map_df(c(1,2,3), function(ordinal_s){
    
    ds <- population %>%
      filter(ordinal == ordinal_s) %>%
      group_by(ordinal, treatment_year)  %>%
      mutate(count = n_distinct(subject_id)) %>%
      filter(count >= 0) %>%
      filter(treatment_year >= '2012-01-01')
    
    if(nrow(ds)==0){return(NULL)}  
    
    dta <- purrr::map_df(list(raw_regimen = "regimen", categorized_regimen = "categorized_regimen"),
                  
    ~ds %>%
      ungroup %>%
      filter(ordinal >= 1 & ordinal <= 3) %>%
      ungroup %>%
      mutate(grouping = .x,
             regimen = .data[[.x]]) %>%
      group_by(grouping, ordinal, regimen) %>%
      group_by(grouping, treatment_year,  ordinal, regimen) %>%
      summarise(count = n()) %>%
      mutate(count = case_when(count <= count_mask ~ as.integer(count_mask), TRUE ~ count)))
    
  })
  }) %>%
  bind_rows(.id = "Population")


km_outputs <- 
  
  purrr::map2(
    list(OS = sym("death_date"),
         TTNT = sym("next_regimen_start"),
         TFI = sym("next_regimen_start"),
         TTD = sym("regimen_end_date")),
    list(OS = sym("regimen_start_date"),
         TTNT =sym("regimen_start_date"),
         TFI =  sym("regimen_end_date"),
         TTD = sym("regimen_start_date")),
    
    function(outcome_col, start_col){
      
      purrr::map(
        list(`First line` = 1,
             `Second line` = 2),
        
        function(line_of_treatment){
          
          data <- formatted_regimens %>%
            group_by(cohort_definition_id, subject_id) %>%
            dplyr::arrange(regimen_start_date) %>%
            mutate(next_regimen_start = lead(regimen_start_date,1)) %>%
            filter(ordinal == line_of_treatment) %>%
            mutate(popn = str_remove(popn, " \\(.*")) %>%
            mutate(end_date = case_when(is.na({{ outcome_col }}) ~ cohort_end_date - {{ start_col }},
                                        TRUE ~ {{ outcome_col }} - {{ start_col }}),
                   has_outcome = !is.na({{ outcome_col }}))
          
          km_data <- 
            purrr::map(
              split(data, data$popn), 
              function(population){
              
                surv_obj <- survfit(Surv(end_date, has_outcome) ~ popn, data=data)
                
                t <- summary(surv_obj)
                
                overall <- tibble(strata = "overall",
                                  time = t$time,
                                  at_risk = t$n.risk,
                                  surv = t$surv,
                                  upper = t$upper,
                                  lower = t$lower) %>%
                  mutate(at_risk = case_when(at_risk <= count_mask ~ as.integer(count_mask), TRUE ~ as.integer(at_risk)))
                
                
                population <- population %>%
                  group_by(categorized_regimen) %>%
                  filter(n() >= count_mask) %>%
                  ungroup
                
                if(nrow(population)==0){table <- NULL}else{
                
                surv_obj <- survfit(Surv(end_date, has_outcome) ~ categorized_regimen, data=population)
                
                t <- summary(surv_obj)
                
                by_treatment <- tibble(strata = coalesce(t$strata,"overall"),
                                       time = t$time,
                                       at_risk = t$n.risk,
                                       surv = t$surv,
                                       upper = t$upper,
                                       lower = t$lower) %>%
                  mutate(at_risk = case_when(at_risk <= count_mask ~ as.integer(count_mask), TRUE ~ as.integer(at_risk)))
                
                }
                
                bind_rows(overall, by_treatment)
            
              }) %>% 
            bind_rows(.id = "population")
          
          return(km_data)
          
        }) %>%
        bind_rows(.id = "line_of_treatment")
      
    })
