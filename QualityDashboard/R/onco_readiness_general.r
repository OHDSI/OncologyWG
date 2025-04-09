library(ggplot2)
library(viridis)
library(dplyr)
library(hrbrthemes)
library(ggdendro)
library(reshape2)
library(pheatmap)  # For heatmap visualization
library(stats)
library(ggraph)
library(igraph)
library(ggrepel)
library(tidyr)
library(reshape2)
library(scales)  
library(ggupset)
library(RColorBrewer) 
library(paletteer)
library(ggbreak)


source("R/db_utilities.r")


generate_overview <- function()
{

# Get bubbles data
#setwd( "/Users/asiehgolozar/Desktop/Work/OHDSI/Onc/Onco Data Readiness/Aggregate results")

# select * from __schema__.records_and_concepts_in_source_and_standard;
# Columns: partner, size, t_records, records_patient, t_source, source_patient, t_standard, standard_patient
#T01<- read.csv("01 Records and concepts in source and standard.csv")
sql <- paste0("select * from ", schema, ".records_and_concepts_in_source_and_standard;")
T01 <- sql_select(sql)

# select * from __schema__.number_of_records_per_domain;
# Columns: partner, domain, records, records_%, concepts, concept_%
#T02<- read.csv("02 Number of records per domain.csv")
sql <- paste0("select * from ", schema, ".number_of_records_per_domain order by partner;")
T02 <- sql_select(sql)

sql <- paste0("
  with maximum1 as (
  select partner, max(\"concept_%\") as \"concept_%\"
  from ", schema, ".number_of_records_per_domain
  where domain in ('Drug', 'Measurement', 'Condition')
  group by partner
  ),
  maximum2 as (
  select partner, domain, \"concept_%\"
  from maximum1
  join ", schema, ".number_of_records_per_domain using(partner, \"concept_%\")
  )
  select partner,
    case
      when \"concept_%\" > 0.5 then domain
    else 'Balanced'
    end as dominant
  from maximum2
  order by partner;")
T02_dom <- sql_select(sql)

# select * from __schema__.count_existing_source_concepts;
# Columns: partner, in_vocab, records, record_%, concepts, concept_%
#T06 <- read.csv("06 Count existing source concepts.csv")
sql <- paste0("select * from ", schema, ".count_existing_source_concepts;")
T06 <- sql_select(sql)

# select * from __schema__.standard_concept_report;
# No idea whether all partners are needed.
# Columns: partner, critique, records, record_%, concepts, concepts_%
#T125 <- read.csv("12.5 Standard concept report.csv")
sql <- paste0("select * from ", schema, ".standard_concept_report;")
T125 <- sql_select(sql)


options(ggrepel.max.overlaps = Inf)
#bubbles 01

Plot_01=T01 %>%
  ggplot(aes(y = records_patient, x = factor(partner), size = size, fill = t_standard)) +  
  geom_segment(aes(x = factor(partner), xend = factor(partner), y = 0, yend = records_patient), color = "grey90", size = 0.5) +  # Decrease line width
  geom_point(aes(color = t_standard), alpha = 0.7, shape = 21) +  # Lollipop heads
  scale_size_continuous(range = c(3, 20), name = "Size", 
                        labels = comma) +  
  scale_fill_viridis(option = "C", direction = -1, name = "Number of distinct standard concepts") +  
  scale_color_viridis(option = "C", direction = -1, guide = "none") +  
  geom_text_repel(aes(label = partner), size = 4, vjust = -1 , color = "black", segment.color = NA, max.overlaps = Inf) +  # Use geom_text_repel to prevent overlap
  labs(x = NULL,  # Remove x-axis label
       y = "Density (#concepts)") +
  
  theme_minimal() +  
  theme(
    plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
    legend.position = "right",  
    panel.grid = element_blank(),  
    axis.text.x = element_blank(),  
    axis.ticks.x = element_blank(),  
    axis.text.y = element_text(size = 12, color = "black"),  
    plot.title = element_text(hjust = 0.5, size = 16, color = "black"),  
    axis.title = element_text(size = 14, color = "black")
  )


ggsave(paste0(output_dir, "Plot_01.jpeg"), plot = Plot_01,bg = "transparent", width = 16, height = 8)

 

# Barplot
Plot_02=T02 %>%
  group_by(partner) %>%
  mutate(`concept_%` = (`concept_%` / sum(`concept_%`)) * 100) %>%  # Normalize to 100%
  ggplot(aes(x = domain, y = `concept_%`, fill = domain), alpha = .6, width = .8) + 
  geom_bar(stat = "identity") + 
  coord_flip() +  
  facet_wrap(~partner, ncol = 6) + 
  scale_fill_viridis(discrete = TRUE) +  
  theme_minimal() +  
  labs(title="", x="Domain", y="Concept Frequency (Normalized to 100%)") +
  scale_y_continuous(breaks = c(0, 25, 50, 75, 100), limits = c(0, 100)) + 
  theme(
    plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
    strip.text = element_text(size = 14, face = "bold"),  
    axis.text.y = element_blank(),  
    axis.text.x = element_text(size = 10, hjust = 1, vjust = 1),  
    legend.position = "bottom",  
    legend.direction = "horizontal",
    legend.text = element_text(color = "black", size = 12),
    legend.key = element_blank(), 
    legend.background = element_rect(fill = NULL, color = NULL), 
    panel.border = element_rect(fill = "transparent", color = "gray50", linewidth = .5), 
    panel.grid.minor = element_blank(), 
    panel.grid.major = element_blank()  
    
  )

ggsave(paste0(output_dir, "Plot_02.jpeg"), plot = Plot_02,bg = "transparent", width = 16, height = 8)
ggsave(paste0(output_dir, "Plot_021.jpeg"), plot = Plot_02,bg = "transparent", width = 10, height = 8)

# 025: similarity plots

# Pivot the data (create wide format where domain becomes columns and concept_. values fill the cells)
pivot_T02 <- T02 %>%
  tidyr::pivot_wider(names_from = domain, values_from = `concept_%`) %>%
  as.data.frame()

# Remove unnecessary columns (records_ and other irrelevant ones if present)
pivot_T02 <- pivot_T02 %>%
  select(-contains(c("records", "concept"))) 

# Shrink data so that each partner has a row and only key domains are included
key_domains <- c("Measurement", "Drug", "Condition", "Observation", "Procedure", "Meas Value", "Device")
pivot_T02_shrunk <- pivot_T02 %>%
#  select(partner, all_of(key_domains)) %>%
  select(partner, any_of(key_domains)) %>%
  group_by(partner) %>%
  summarise(across(everything(), \(x) sum(x, na.rm = TRUE)))

# View the final pivoted and shrunk data
print(pivot_T02_shrunk)

## MSD plot
# Prepare the data by removing the 'partner' column and converting to a matrix
mds_T02<- pivot_T02_shrunk[ , -1]  

# Calculate the distance matrix using Euclidean distance
distance_matrix_T02 <- dist(mds_T02, method = "euclidean")

# Perform MDS
mds_result02 <- cmdscale(distance_matrix_T02, k = 2)  # Reduce to 2 dimensions

# Create a data frame for plotting
mds_plot_T02 <- as.data.frame(mds_result02)
mds_plot_T02$partner <- pivot_T02_shrunk$partner  # Add partner names
mds_plot_T02 <- merge(mds_plot_T02, T02_dom, by = "partner")

# Use the first MDS dimension (V1) to assign colors (more similar partners get similar colors)
Plot_025=ggplot(mds_plot_T02, aes(x = V1, y = V2)) +
  geom_point(size = 3, color = "#336B91") +  # Set point color directly
  geom_text_repel(
    aes(label = partner), 
    size = 4.5,  
    color = "black",  
    box.padding = 0.5,  
    point.padding = 0.3,  
    segment.color = "grey80", 
    segment.size = 0.5,  # Decrease line thickness for connecting lines
    max.overlaps = Inf  
  ) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
    legend.position = "none", 
    panel.grid = element_blank(),  
    axis.text.x = element_blank(),  
    axis.ticks.x = element_blank(),  
    axis.text.y = element_blank(),  
    axis.title = element_blank()  
  )

ggsave(paste0(output_dir, "Plot_025.jpeg"), plot = Plot_025,bg = "transparent", width = 10, height = 8)
 #### another one: 

### colore version 
custom_colors <- c(
  "Group 1" = "#336B91",
  "Group 2" = "#FBC511",
  "Group 3" = "#E63946",
  "Group 4" = "#A8DADC"
)

mds_plot_T02 <- mds_plot_T02 %>%
  mutate(
    color_group = case_when(
      dominant %in% c("Condition") ~ "Group 1",
      dominant %in% c("Drug") ~ "Group 2",
      dominant %in% c("Measurement") ~ "Group 3",
      TRUE ~ "Group 4" # All other partners
    )
  )
mds_plot_T02 <- mds_plot_T02 %>% select(-dominant)

# EXTRA WITH COLORS FOR MARKDOWN Create the plot with legend at the bottom and split into two rows
Plot_025 <- ggplot(mds_plot_T02, aes(x = V1, y = V2)) +
  geom_point(aes(color = color_group), size = 3) +  
  geom_text_repel(
    aes(label = partner), 
    size = 4.5,
    color = "black",
    box.padding = 0.5,
    point.padding = 0.3,
    segment.color = "grey80",
    segment.size = 0.5,
    max.overlaps = Inf
  ) +
  scale_color_manual(
    values = custom_colors,
    labels = c(
      "Group 1" = "Conditions dominate",
      "Group 2" = "Drugs dominate",
      "Group 3" = "Measurements dominate",
      "Group 4" = "Balanced"
    )
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) + # Arrange legend into two rows
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
    legend.position = "bottom", # Move legend to the bottom
    legend.title = element_blank(), 
    legend.text = element_text(size = 12), 
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title = element_blank()
  )
# Create the plot with legend at the bottom and split into two rows
Plot_025 <- ggplot(mds_plot_T02, aes(x = V1, y = V2)) +
  geom_point(aes(color = color_group), size = 3) +  # Map color to the new column
  geom_text_repel(
    aes(label = partner), 
    size = 4.5,
    color = "black",
    box.padding = 0.5,
    point.padding = 0.3,
    segment.color = "grey80",
    segment.size = 0.5,
    max.overlaps = Inf
  ) +
  scale_color_manual(
    values = custom_colors,
    labels = c(
      "Group 1" = "Conditions dominate",
      "Group 2" = "Drugs dominate",
      "Group 3" = "Measurements dominate",
      "Group 4" = "Balanced"
    )
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) + # Arrange legend into two rows
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
    legend.position = "bottom", 
    legend.title = element_blank(), 
    legend.text = element_text(size = 12), 
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_blank(),
    axis.title = element_blank()
  )

# Display the plot
print(Plot_025)
ggsave(paste0(output_dir, "Plot_025.jpeg"), plot = Plot_025,bg = "transparent", width = 10, height = 8)


# 06- CREATE A NEW ONE
#stupid pie charts
custom_colors6 <- c("Known" = "white", "Unknown" = "#336B91", "NULL" = "#FBC511")
T06$in_vocab<- factor(T06$in_vocab, levels = c(sort(setdiff(unique(T06$in_vocab), "Known")), "Known"))

Plot_06=T06%>%
  ggplot(aes(x = "", y = `concept_%`,  fill = in_vocab, color = in_vocab)) +  
  geom_bar(stat = "identity", width = 1) +  
  coord_polar(theta = "y", start=0, direction=-1) +  
  geom_label_repel(aes(label = ifelse(in_vocab %in% c("Unknown", "NULL") & `concept_%` > 0, 
                                      paste0(round(10000 * `concept_%`, digits = 2) / 100, "%"), 
                                      "")), size = 3, color = "black",  fill = "white", 
                   show.legend = FALSE, 
                   force = 25,  
                   max.overlaps = Inf,  
                   box.padding = 0.01,  
                   point.padding = 0.01  
       ) +
  labs(x = NULL, y = NULL, fill ="", color="")+
  scale_fill_manual(values = custom_colors6, breaks = names(custom_colors6)[names(custom_colors6) != "Known"]) +  
  scale_color_manual(values = custom_colors6, breaks = names(custom_colors6)[names(custom_colors6) != "Known"]) +  
  theme_minimal() +
  theme(
        plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
        axis.text.x = element_blank(),  
        axis.ticks = element_blank(),  
        panel.grid = element_blank(),  
        strip.text = element_text(size = 10), 
        legend.position = "none", 
        legend.title = element_blank(),  
        legend.key = element_blank())  +  
  facet_wrap(~ partner, ncol=9)

ggsave(paste0(output_dir, "Plot_06.jpeg"), plot = Plot_06,bg = "transparent", width = 12, height = 8)


 
#125
  
# Step 1: Calculate the sum of concepts_. for each partner excluding "Great"
sum_concepts <- T125 %>%
  group_by(partner) %>%
  summarise(total_concepts = sum(`concepts_%`, na.rm = TRUE), .groups = 'drop')
  
# Step 2: Create the new category "Great"
great_data <- sum_concepts %>%
  mutate(critique = "Great",
         `concepts_%` = 1 - total_concepts) %>%
        select(partner, critique, `concepts_%`)
  
# Step 3: Add Maas NSCLC to the great_data
great_data <- great_data %>%
  bind_rows(tibble(partner = "Maas NSCLC", critique = "Great", `concepts_%` = 1))  # Ensure concepts_ = 1 for Maas NSCLC
  
  # Step 4: Combine the new "Great" data with the original data
T125_updated <- T125 %>%
  bind_rows(great_data)
  
# Check the updated data frame
print(T125_updated)
  
# Get the NEJM color palette from ggsci
nejm_colors <- paletteer::paletteer_d("ggsci::default_nejm", n = length(unique(T125_updated$critique)) - 1)
  
# Combine colors for "Great" and NEJM colors
# Combine all unique critique categories from the three datasets
all_critiques <- unique(c(T125$critique))


common_colors <- c(
  "Concept 0" = "#9590FF",
  "Invalid grade" = "#A3A500",
  "Invalid met or node" =  "#e38826",
  "Invalid stage" = "#39B600",
  "Not standard concept" = "#0063a6",
  "Wrong domain table" =  "#F8766D" , 
  "Wrong vocab for domain"="#00BFC4",
  "Wrong vocab for domain"="#FF62BC", 
  "Great"="#ce2029"
)


# Ensure only the colors for the critiques present in the datasets are used
common_colors <- common_colors[names(common_colors) %in% all_critiques]

Plot_125 <- T125_updated %>%
  ggplot(aes(x = "", y = `concepts_%`, fill = critique, color = critique)) +  
  geom_bar(stat = "identity", width = 1.2) +  
  coord_polar(theta = "y", start=0, direction=1) +  
  labs(x = NULL, y = NULL, fill = "", color = "") +
  theme_minimal() +
  scale_fill_manual(values = common_colors, breaks = names(common_colors)[names(common_colors) != "Great"], na.translate = FALSE) +  
  scale_color_manual(values = common_colors, breaks = names(common_colors)[names(common_colors) != "Great"],  na.translate = FALSE) +  # Ensure borders match fill colors and exclude "Great" from the legend
  theme(
        plot.background = element_rect(fill = "transparent", color = NA), # Set background to transparent
        axis.text.x = element_blank(), 
        axis.ticks = element_blank(),  
        panel.grid = element_blank(),  
        strip.text = element_text(size = 10), 
        legend.position = "right",
        legend.title = element_blank(),  
        legend.key = element_blank()) +  
  facet_wrap(~ partner, ncol = 9)  
ggsave(paste0(output_dir, "Plot_125.jpeg"), plot = Plot_125,bg = "transparent", width = 12, height = 8)




# Copy the plot images to the web directory.
# It's possible the R user needs to be granted write access to the target directory.

#target_dir <- "/var/www/html/wp-content/uploads/2025/01/"

file.copy(paste0(output_dir, "Plot_01.jpeg"), paste0(target_dir, "Plot_01.jpeg"), overwrite = TRUE)
file.copy(paste0(output_dir, "Plot_02.jpeg"), paste0(target_dir, "Plot_02.jpeg"), overwrite = TRUE)
file.copy(paste0(output_dir, "Plot_06.jpeg"), paste0(target_dir, "Plot_06.jpeg"), overwrite = TRUE)
file.copy(paste0(output_dir, "Plot_025.jpeg"), paste0(target_dir, "Plot_025.jpeg"), overwrite = TRUE)
file.copy(paste0(output_dir, "Plot_125.jpeg"), paste0(target_dir, "Plot_125.jpeg"), overwrite = TRUE)
}
