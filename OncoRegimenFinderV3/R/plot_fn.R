plot_fn <- function(person_data, colours_to_use){
  
  num_drugs <- n_distinct(person_data$concept_name)
  date_range <- as.integer(max(person_data$ingredient_start_date + person_data$days_supply) - min(person_data$ingredient_start_date)) %>%
    max(30)
  
  new_drugs <- setdiff(person_data$concept_name, names(colours_to_use))
  
  if(length(new_drugs) > 0){new_colours <- setNames(c("#FBB4AE","#B3CDE3","#CCEBC5","#DECBE4","#FED9A6","#FFFFCC","#E5D8BD","#FDDAEC","#F2F2F2")[1:length(new_drugs)], new_drugs)}
  else{new_colours <- c()}
  
  all_cols <- c(colours_to_use, new_colours)
  
  plot <- person_data %>%
    filter(type %in% c("exposures", "regimen ingredients")) %>%
    mutate(days_supply = pmax(0,days_supply)) %>%
    arrange(ingredient_start_date,  concept_name) %>%
    mutate(concept_name = factor(concept_name, levels = rev(unique(concept_name)), ordered = T),
           concept_name_id = as.numeric(concept_name),
           concept_name = as.character(concept_name),
           day_start = ingredient_start_date - min(ingredient_start_date),
           day_start_2 = day_start,
           day_end = day_start + pmax(days_supply - 1,0)) %>%
    select(-ingredient_start_date, -days_supply) %>%
    gather(event, day, -c("person_id","concept_name","concept_name_id","group","day_start_2","type","regimen_group")) %>%
    ggplot(aes(x = day, y = concept_name_id, colour = concept_name)) +
    geom_line(aes(x = day, y = concept_name_id, colour = concept_name, group = regimen_group), colour = "black", linetype ="solid", size = 1) +
    geom_line(aes(x = day, y = concept_name_id, colour = concept_name, group = group), size = 1) +
    geom_point(aes(x = day_start_2, y = concept_name_id, fill = concept_name), colour = 'black', pch = 22, size = 4) +
    theme_light() +
    ylab("") +
    scale_colour_manual(values = all_cols) +
    scale_fill_manual(values = all_cols) +
    scale_x_continuous(limits = c(min(c(-5, person_data$days_supply)), 1.2*date_range)) +
    scale_y_continuous(labels = NULL, breaks = seq(1:num_drugs), limits = c(0,num_drugs+1)) +
    ggtitle(str_c("Exposures + regimens (",person_data$person_id[1],")")) +
    facet_grid(type ~ .)
  
  annotations <- person_data %>%
    arrange(ingredient_start_date, concept_name) %>%
    mutate(concept_name = factor(concept_name, levels = rev(unique(concept_name)), ordered = T),
           concept_name_id = as.numeric(concept_name)) %>%
    filter(type == "regimen ingredients") %>%
    mutate(day = ingredient_start_date - min(ingredient_start_date)) %>%
    group_by(regimen_group, day, type) %>%
    mutate(min_id = min(concept_name_id),
           text = ifelse(concept_name_id != min_id,
                         str_c(concept_name, " +"),
                         str_c(concept_name)))
  plot # + 
  #  geom_text(data = annotations, aes(x = day, y = concept_name_id, label = text), colour = "black", hjust = -0.2, vjust = 0.5)
  
}


