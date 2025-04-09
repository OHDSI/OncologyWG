# Load necessary libraries
library(readr)
library(dplyr)
library(ggplot2)
library(rmarkdown)
library(tidyr)
library(ggrepel)
library(viridis)
library("tinytex")

source("R/db_utilities.r")

# Set output directory
#output_dir <- "/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Reports/CSV"
#dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

generate_partner_output <- function(partner_name)
{
  # Read and preprocess data
  # select * from __schema__.individual_concept_report
  # where partner = '__partner_name__';
  # Columns: partner, concept, concept_id, concept_name, vocabulary_id, domain_id, is_domain, critique, records
  #data <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Individual concept report.txt", delim = "\t", col_names = TRUE)

#    sql_send("SET statement_timeout = 1;")    
    sql <- paste0("select * from ", schema, 
                        ".individual_concept_report where partner = '", partner_name, "';")
    data <- sql_select(sql)

	sql <- paste0("select concept, concept_id, concept_name, vocabulary_id, domain_id, is_domain, critique, sum(records) as records
		from ", schema, ".individual_concept_report
		group by concept, concept_id, concept_name, vocabulary_id, domain_id, is_domain, critique;")
	
	data_all <- sql_select(sql)
    
  # select * from __schema__.database_summary
  # where partner = '__partner_name__';
  # Columns: partner, size, general, genomic, episodes
  # database_summary <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Database summary.txt", delim = "\t", col_names = TRUE)
    sql <- paste0("select * from ", schema, 
                  ".database_summary where partner = '", partner_name, "';")
    database_summary <- sql_select(sql)
  
  # select * from __schema__.domain_weights;
  # Columns: partner, domain, records, records_%
  #T021 <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Domain weights.txt", delim = "\t", col_names = TRUE)
  #T021 <- T021 %>%
  #  rename(record_. = `records_%`)
    
    sql <- paste0("select * from ", schema, ".domain_weights order by partner;")
    T021 <- sql_select(sql)
  
    # Columns: partner, dominant
    # T021_dom <- insert database call here
    sql <- paste0("
  with maximum1 as (
  select partner, max(\"record_%\") as \"record_%\"
  from ", schema, ".domain_weights
  where domain in ('Drug', 'Measurement', 'Condition')
  group by partner
  ),
  maximum2 as (
  select partner, domain, \"record_%\"
  from maximum1
  join ", schema, ".domain_weights using(partner, \"record_%\")
  )
  select partner,
    case
      when \"record_%\" > 0.5 then domain
    else 'Balanced'
    end as dominant
  from maximum2
  order by partner;")
  T021_dom <- sql_select(sql)
  
  
  # select * from __schema__.rolled_up_tumor_types;
  # Columns: partner, cancer_type, records, record_%
  # T051 <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Rolled-up tumor types.txt", delim = "\t", col_names = TRUE)
  # T051 <- T051 %>%
  #   rename(record_. = `record_%`)
  sql <- paste0("select * from ", schema, ".rolled_up_tumor_types;")
  T051 <- sql_select(sql)
  
  # select * from __schema__.source_summary_report
  # where partner = '__partner_name__';
  # Columns: partner, critique, records, record_%
  # T061 <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Source summary report.txt", delim = "\t", col_names = TRUE)
  # T061 <- T061 %>%
  #   rename(record_. = `record_%`)
  sql <- paste0("select * from ", schema, 
                ".source_summary_report where partner = '", partner_name, "';")
  T061 <- sql_select(sql)
  
  
  # select * from __schema__.mapping_summary_report
  # where partner = '__partner_name__';
  # Columns: partner, critique, records, record_%
  sql <- paste0("select * from ", schema, 
                ".mapping_summary_report where partner = '", partner_name, "';")
  T08 <- sql_select(sql)
  
  # select * from __schema__.standard_summary_report
  # where partner = '__partner_name__';
  # Columns: partner, critique, records, record_%
  # T09 <- read_delim("/Users/asiehgolozar/Library/CloudStorage/OneDrive-SharedLibraries-OncoNemesis/Nemesis - Documents/Oncology/Onc data readiness/Aggregate results/Standard summary report.txt", delim = "\t", col_names = TRUE)
  # T09 <- T09 %>%
  #   rename(record_. = `record_%`)
  sql <- paste0("select * from ", schema, 
                ".standard_summary_report where partner = '", partner_name, "';")
  T09 <- sql_select(sql)
  
  
  # This is for the current partner.
  data$concept_name <- iconv(data$concept_name, from = "", to = "UTF-8", sub = "byte")
  # Trim 'concept_name' to 50 characters for better readability
  data$concept_name <- ifelse(
    nchar(data$concept_name) > 50, 
    paste0(substr(data$concept_name, 1, 50), "..."), 
    data$concept_name
  )
  
  # Write a single CSV file for the partner's issues (excluding partner column)
  all_issues_csv <- file.path(output_dir, paste0(partner_name, "_all_issues.csv"))
  write.csv(data %>% select(-partner), all_issues_csv, row.names = FALSE)
  
  # This is for all partners.
  data_all$concept_name <- iconv(data_all$concept_name, from = "", to = "UTF-8", sub = "byte")
  # Trim 'concept_name' to 50 characters for better readability
  data_all$concept_name <- ifelse(
    nchar(data_all$concept_name) > 50, 
    paste0(substr(data_all$concept_name, 1, 50), "..."), 
    data_all$concept_name
  )
  
  # Write a single CSV file for all issues (excluding partner column)
  all_issues_csv <- file.path(output_dir, "all_issues.csv")
  write.csv(data_all, all_issues_csv, row.names = FALSE)
  
  
  #### Fig 2 Distribution of cancers ####
  # Fig 2 Step 1: Preprocess T05 dataset for scaled records
  max_records <- T051 %>%
    group_by(partner) %>%
    summarise(
      max_record = if (all(is.na(`record_%`))) NA else max(`record_%`, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Fig 2 Step 2: Join max_records back to T05 and scale record_
  T051_scaled <- T051 %>%
    left_join(max_records, by = "partner") %>%
    mutate(scaled_record = `record_%` / max_record)  
  
  # Fig 2 Step 3: Calculate average scaled_record by cancer_type
  average_scaled <- T051_scaled %>%
    group_by(cancer_type) %>%
    summarise(avg_scaled_record = mean(`record_%`, na.rm = TRUE), .groups = 'drop') %>%
    arrange(desc(avg_scaled_record))  # Order by average scaled_record
  
  # Fig 2 Step 4: Create a complete list of partners and cancer types
  all_partners <- unique(T051_scaled$partner)
  all_cancer_types <- unique(average_scaled$cancer_type)
  
  # Fig 2 Step 5: Expand the dataset to include all partners and cancer types, even if some data is missing
  T051_scaled_complete <- T051_scaled %>%
    complete(partner = all_partners, cancer_type = all_cancer_types)  # Ensure all combinations are present
  
  # Fig 2 Step 6: Ensure consistent factor levels for cancer_type across all partners
  T051_scaled_complete <- T051_scaled_complete %>%
    mutate(cancer_type = factor(cancer_type, levels = all_cancer_types))  # Set fixed levels for cancer_type
  ######## 
  
  #### Fig 3 Distribution of cancers in the network ####
  # Aggregate data for all partners
  cancer_distribution =as.data.frame(T051 %>%
    group_by(cancer_type) %>%
    summarise(total_records = sum(`record_%`, na.rm = TRUE),.groups = 'drop') %>%
    arrange(desc(total_records))) 
  
  # Create the distribution plot of cancers across the data partners
  cancer_distribution_plot=ggplot(cancer_distribution, aes(x = reorder(cancer_type, -total_records), y = total_records, color = reorder(cancer_type, -total_records))) +
    geom_point(size = 3, alpha = 0.7) +
    labs(y = "") +
    scale_color_viridis_d(option = "C", name = NULL) +
    theme_minimal() +
    theme_minimal() +
    theme(
      strip.text = element_text(size = 12),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      axis.title.y = element_text(size = 14, color = "black"),
      legend.position = "none",
      panel.grid.major=element_blank(),
      panel.grid.minor=element_blank(),
      panel.border=element_rect(fill="transparent",color="gray75",linewidth=.5)
    ) +
    guides(color=guide_legend(ncol=9), byrow=TRUE)
  
  # Save the plot as an image file

  plot_path <- file.path(output_dir, "cancer_distribution_plot.png")
  ggsave(plot_path, plot=cancer_distribution_plot, width = 5, height = 3)
  ######## 
  
  #### Fig 4 Cancer type distance plot between data partners ####
  # Fig 4: Reshape the data (pivot wider) so that rows are partners and columns are cancer types
  pivot_data <- T051 %>%
    tidyr::pivot_wider(names_from = cancer_type, values_from = `record_%`) %>%
    as.data.frame()
  
  
  pivot_data <- pivot_data %>%
    select(-contains(c("records")))  
  
  key_domains <- colnames(pivot_data)[-1]
  pivot_data_shrunk <- pivot_data %>%
    select(partner, all_of(key_domains)) %>%
    group_by(partner) %>%
    summarise(across(everything(), \(x) sum(x, na.rm = TRUE)))  # Ensure that the values are aggregated if multiple rows exist per partner
  ############
  
  #### Fig 6  Domain weight distance plot of data partners with annotation ####
  # Prepare data for MDS Plot (mds_plot_T02)
  # we need at least 4 partner: if we had 3, the focus partner would be excluded for fig 4,
  # so the remaining distance matrix has only 1 entry and cmdscale will fail.
  if (n_distinct(T021$partner) < 4)
    return("")
  
  pivot_T021 <- T021 %>%
    tidyr::pivot_wider(names_from = domain, values_from = `record_%`) %>%
    as.data.frame() %>%
    select(-contains(c("records", "concept"))) %>% 
  #  select(partner, all_of(c("Measurement", "Drug", "Condition", "Observation", "Procedure", "Meas Value", "Device"))) %>%
    select(partner, any_of(c("Measurement", "Drug", "Condition", "Observation", "Procedure", "Meas Value", "Device"))) %>%
    group_by(partner) %>%
    summarise(across(everything(), \(x) sum(x, na.rm = TRUE)))
  
  # Check if pivot_T02 has valid rows
  if (nrow(pivot_T021) == 0) {
    stop("No valid data available for MDS plot.")
  }
  
  mds_T021 <- pivot_T021[ , -1]  # Remove 'partner' column
  distance_matrix_T021 <- dist(mds_T021, method = "euclidean")
  mds_result_T021 <- cmdscale(distance_matrix_T021, k = 2)  # Reduce to 2 dimensions
  
  # Create a data frame for plotting
  mds_plot_T021 <- as.data.frame(mds_result_T021)
  mds_plot_T021$partner <- pivot_T021$partner
  mds_plot_T021 <- merge(mds_plot_T021, T021_dom, by = "partner")

  ############
  
  #### Fig 7 Anomalies with source concepts. ####
  # Step 1: Calculate the sum of concepts_. for each partner excluding "Great"
  sum_records61 <- T061 %>%
    group_by(partner) %>%
    summarise(total_records = sum(`record_%`, na.rm = TRUE), .groups = 'drop')
  
  # Step 2: Create the new category "Great"
  great_data61 <- sum_records61 %>%
    mutate(critique = "Great",
           `record_%` = 1 - total_records) %>%
    select(partner, critique, `record_%`)
  # Step 4: Combine the new "Great" data with the original data
  T061_updated <- T061 %>%
    bind_rows(great_data61)
  ############ 
  
  #### Fig 8 Mapping anomalies for source concepts. ####
  # Step 1: Calculate the sum of concepts_. for each partner excluding "Great"
  sum_records8 <- T08 %>%
    group_by(partner) %>%
    summarise(total_records = sum(`record_%`, na.rm = TRUE), .groups = 'drop')
  
  # Step 2: Create the new category "Great"
  great_data8 <- sum_records8 %>%
    mutate(critique = "Great",
           `record_%` = 1 - total_records) %>%
    select(partner, critique, `record_%`)
  # Step 3: Add Maas NSCLC to the great_data
  great_data8 <- great_data8 %>%
    bind_rows(tibble(partner = "Maas NSCLC", critique = "Great", `record_%` = 1))  # Ensure concepts_ = 1 for Maas NSCLC
  
  # Step 4: Combine the new "Great" data with the original data
  T08_updated <- T08 %>%
    bind_rows(great_data8)
  ############
  
  #### Fig 9  Anomalies with standard concepts ####
  # Step 1: Calculate the sum of concepts_. for each partner excluding "Great"
  sum_records9 <- T09 %>%
    group_by(partner) %>%
    summarise(total_records = sum(`record_%`, na.rm = TRUE), .groups = 'drop')
  
  # Step 2: Create the new category "Great"
  great_data9 <- sum_records9 %>%
    mutate(critique = "Great",
           `record_%` = 1 - total_records) %>%
    select(partner, critique, `record_%`)
  
  # Step 3: Add Maas NSCLC to the great_data
  great_data9 <- great_data9 %>%
    bind_rows(tibble(partner = "Maas NSCLC", critique = "Great", `record_%` = 1))  # Ensure concepts_ = 1 for Maas NSCLC
  
  # Step 4: Combine the new "Great" data with the original data
  T09_updated <- T09 %>%
    bind_rows(great_data9)
  
  # Combine all unique critique categories from the three datasets
  all_critiques <- unique(c(T08$critique))
  
  ############
  
  # Function to filter and format issues by partner
  get_issues_by_partner <- function(data, partner) {
    filtered_data <- data %>%
      filter(partner == !!partner) %>%
      select(
        concept,
        concept_id,
        concept_name,
        vocabulary_id,
        domain_id,
        is_domain,
        critique,
        records
      ) %>%
      rename(
        `Concept Type` = concept,
        `Concept ID` = concept_id,
        `Concept Name` = concept_name,
        `Vocabulary ID` = vocabulary_id,
        `Domain ID` = domain_id,
        `Is Domain` = is_domain,
        `Critique` = critique,
        `Records` = records
      )
    
    return(filtered_data)
  }
  
  # Get unique partners from the dataset
  partners <- unique(data$partner)
  
  # Path to the R Markdown template
  template_path <- "report_template_pdf.Rmd"
  
  # Markdown cannot deal with files not in the current directory,
  # so we need to copy them once
  if (!file.exists(template_path)) 
  {
    file.copy(paste0("R/", template_path), template_path)
    file.copy("R/Summary of the query.png", "Summary of the query.png")
    file.copy("R/cancer_distribution_plot.png", "cancer_distribution_plot.png")
  }
  

  # Render reports for each partner

  # Prepare data for Fig 6
  mds_plot_T021 <- mds_plot_T021 %>%
    mutate(
      color_group = case_when(
        dominant %in% c("Condition") ~ "Group 1",
        dominant %in% c("Drug") ~ "Group 2",
        dominant %in% c("Measurement") ~ "Group 3",
        TRUE ~ "Group 4" # All other partners
      )
    )
  mds_plot_T021 <- mds_plot_T021 %>% select(-dominant)

  for (partner in partners) {
    # Filter issues for the current partner
    issues <- get_issues_by_partner(data, partner)
    
    # Check if there are any issues for the partner
    if (nrow(issues) == 0) {
      cat("No issues found for", partner, "\n")
      next # Skip rendering if no issues exist for this partner
    }
    
    # Calculate total patients 
    total_patients <- format(database_summary$size[database_summary$partner == partner], big.mark = ",", scientific = FALSE)
  
    #replace NAs with zero 
    database_summary[is.na(database_summary)] <- 0
    
    # Calculate general record per partner 
    general_records <- format(database_summary$general[database_summary$partner == partner], big.mark = ",", scientific = FALSE)
    
    # Calculate genomic record per partner 
    genomic_records <- format(database_summary$genomic[database_summary$partner == partner], big.mark = ",", scientific = FALSE)
    
    # Calculate episode record per partner 
    episode_records <- format(database_summary$episodes[database_summary$partner == partner], big.mark = ",", scientific = FALSE)
    
    # Prepare data for Fig 2
    # Filter T05_scaled_complete for the current partner
    partner_plot_data <- T051_scaled_complete %>% filter(partner == !!partner)
    
    # Prepare data for Fig 4
    # Step 1: Prepare data by removing 'partner' column and ensuring numeric columns
    mds_data <- pivot_data_shrunk %>% select(-partner)
    
    # Check if all columns are numeric
    if (!all(sapply(mds_data, is.numeric))) {
      stop("All columns in mds_data must be numeric for distance matrix calculation.")
    }
    
    #Fig 4 Step 1: Calculate distance matrix using Euclidean distance
    distance_matrix <- dist(mds_data, method = "euclidean")
    
    # Fig 4 Step 2: Perform MDS
    mds_result <- cmdscale(distance_matrix, k = 2)  # Reduce to 2 dimensions
    
    # Fig 4 Step 3: Create a data frame for plotting
    mds_plot_data <- as.data.frame(mds_result)
    mds_plot_data$partner <- pivot_data_shrunk$partner
  
    # Prepare data for Fig 5
    # Filter T02_scaled_complete for the current partner
    plot_05_data <- T021 %>%
      filter(partner == !!partner) %>%
      group_by(partner) %>%
      mutate(`record_%` = (`record_%` / sum(`record_%`)) * 100) # Normalize to 100%
  
    custom_colors <- c(
      "Group 1" = "#336B91",
      "Group 2" = "#FBC511",
      "Group 3" = "#E63946",
      "Group 4" = "#A8DADC"
    )
    
  
    # Prepare data for Fig 7
    plot_07_data <- T061_updated %>% filter(partner == !!partner)
    
    # Prepare data for Fig 8
    plot_08_data <- T08_updated %>% filter(partner == !!partner)
  
    # Prepare data for Fig 9
    plot_09_data <- T09_updated %>% filter(partner == !!partner)
    
    # Separate issues into categories based on critique
    issues_mapping <- issues %>% filter(`Concept Type` == "Source" & grepl("mapping", Critique, ignore.case = TRUE))
    issues_mapping <- issues_mapping %>%  select(-c(`Concept Type`, `Domain ID`, `Is Domain`))
    
    issues_other <- issues %>% filter(`Concept Type` == "Source" & !grepl("mapping", Critique, ignore.case = TRUE))
    issues_other <- issues_other %>% select(-c(`Concept Type`, `Domain ID`, `Is Domain`))
    
    issues_standard <- issues %>% filter(`Concept Type` == "Standard")
    issues_standard <- issues_standard %>% select(-c(`Concept Type`, `Domain ID`, `Is Domain`))

    # Prevent log file
    Sys.setenv(R_PANDOC_LATEX_ARGS="--pdf-engine-opt=-interaction=batchmode")
    #library(knitr)
    #opts_knit$set(tidy = TRUE)
    # Render the R Markdown report for the current partner
    rmarkdown::render(
      output_format = pdf_document(latex_engine = "xelatex"
                                   #, pandoc_args = "--pdf-engine-opt=-interaction=batchmode"
        ),
      #clean = TRUE,
      #quiet = TRUE,
      input = template_path,
      output_file = paste0(partner, "_report.pdf"),
      params = list(
        partner = partner,
        total_patients = total_patients,
        general_records = general_records,
        genomic_records = genomic_records,
        episode_records = episode_records,
        issues_source_mapping = issues_mapping,
        issues_source_other = issues_other,
        issues_standard = issues_standard,
        all_issues_csv_path = all_issues_csv,
        plot_02_data = partner_plot_data,
        plot_04_data = mds_plot_data,
        plot_05_data = plot_05_data,
        plot_06_data = mds_plot_T021,
        plot_07_data = plot_07_data,
        plot_08_data = plot_08_data,
        plot_09_data = plot_09_data
      ),
      envir = new.env() # Use a clean environment for rendering
    )
    
    file.rename(paste0(partner, "_report.pdf"), paste0(output_dir, partner, "_report.pdf"))
    mk_log_file <- paste0(partner, "_report.log")
    if (file.exists(mk_log_file))
      file.remove(mk_log_file)

    cat("Generated report for", partner, "\n")
  }
  
  return(paste0(output_dir, partner_name, "_report.pdf"))
}

