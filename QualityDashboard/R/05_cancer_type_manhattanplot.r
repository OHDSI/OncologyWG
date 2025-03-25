# Load necessary libraries
library(ggplot2)
library(ggrepel)
library(viridis)
library(dplyr)
library(tidyr)

#db_open(db_params)
generate_overview2 <- function()
{
# Step 1: Load your dataset (adjust the file path as needed)
# select * from __schema__.rolled_up_tumor_types_for_each_partner;
# Columns: partner, cancer_type, records, record_%
#T05 <- read.csv("05 Rolled-up tumor types for each partner.csv")
sql <- paste0("select * from ", schema, ".rolled_up_tumor_types_for_each_partner;")
T05 <- sql_select(sql)

# Step 1: Calculate max record_% per partner

max_records <- T05 %>%
  group_by(partner) %>%
  summarise(
    max_record = if (all(is.na(`record_%`))) NA else max(`record_%`, na.rm = TRUE),
    .groups = 'drop'
  )

# Step 2: Join max_records back to T05 and scale record_%
T05_scaled <- T05 %>%
  left_join(max_records, by = "partner") %>%
  mutate(scaled_record = `record_%` / max_record)  

# Step 3: Calculate average scaled_record by cancer_type
average_scaled <- T05_scaled %>%
  group_by(cancer_type) %>%
  summarise(avg_scaled_record = mean(`record_%`, na.rm = TRUE), .groups = 'drop') %>%
  #summarise(avg_scaled_record = mean(scaled_record, na.rm = TRUE), .groups = 'drop') %>%
  arrange(desc(avg_scaled_record))  # Order by average scaled_record

# Step 4: Create a complete list of partners and cancer types
all_partners <- unique(T05_scaled$partner)
all_cancer_types <- unique(average_scaled$cancer_type)

# Step 5: Expand the dataset to include all partners and cancer types, even if some data is missing
T05_scaled_complete <- T05_scaled %>%
  complete(partner = all_partners, cancer_type = all_cancer_types) 

# Step 6: Ensure consistent factor levels for cancer_type across all partners
T05_scaled_complete <- T05_scaled_complete %>%
  mutate(cancer_type = factor(cancer_type, levels = all_cancer_types))  

# Step 7: Plot the data, ensuring consistent x-axis alignment and empty plots for partners with no data
# Manhattan plots 
Plot_05=T05_scaled_complete %>%
  filter(is.na(`record_%`) | `record_%` > 0) %>%  
  ggplot(aes(x = cancer_type, y = scaled_record, color = cancer_type)) +
  geom_point(size = 3, alpha = 0.7, na.rm = TRUE) + 
  facet_wrap(~ partner, scales = "fixed", ncol=6) + 
  scale_color_viridis_d(option = "C", name = NULL) +  
  labs(y = "Scaled Record %") + 
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = "white"), # Set background to transparent
    strip.text = element_text(size = 12),
    axis.text.x = element_blank(),  
    axis.ticks.x = element_blank(),  
    axis.title.x = element_blank(),  
    axis.text.y = element_text(size = 10, color = "black"),
    plot.title = element_text(hjust = 0.5, size = 16, color = "black"),
    axis.title.y = element_text(size = 14, color = "black"), 
    legend.position = "bottom",  
    legend.title = element_text(size = 7), 
    legend.text = element_text(size = 7),  
    legend.key.size = unit(0.2, "cm"),  
    legend.spacing.y = unit(0.02, 'cm'),  
    legend.box.spacing = unit(0.1, "cm"),  
    legend.margin = margin(t = 0.1, r = 0, b = 0.1, l = 0, unit = 'cm'),  
    panel.grid.major = element_blank(),  
    panel.grid.minor = element_blank(), 
    panel.border = element_rect(fill = "transparent", color = "gray75", linewidth = .5)
  ) +
  guides(color = guide_legend(ncol = 9), byrow=TRUE)  

ggsave(paste0(output_dir, "Plot_05.jpeg"), plot = Plot_05,bg = "white", width = 26, height = 12)






## MSD plot
# Step 2: Reshape the data (pivot wider) so that rows are partners and columns are cancer types
pivot_data <- T05 %>%
  tidyr::pivot_wider(names_from = cancer_type, values_from = `record_%`) %>%
  as.data.frame()

pivot_data <- pivot_data %>%
  select(-contains(c("records")))  

key_domains <- colnames(pivot_data)[-1]
pivot_data_shrunk <- pivot_data %>%
  select(partner, all_of(key_domains)) %>%
  group_by(partner) %>%
  summarise(across(everything(), sum, na.rm = TRUE))  



## MSD plot
# Step 1: Prepare the data by removing the 'partner' column and converting to a matrix
mds_data <- pivot_data_shrunk[ , -1]  

# Step 2: Calculate the distance matrix using Euclidean distance
distance_matrix <- dist(mds_data, method = "euclidean")

# Step 3: Perform MDS
mds_result <- cmdscale(distance_matrix, k = 2)  # Reduce to 2 dimensions

# Step 4: Create a data frame for plotting
mds_plot_data <- as.data.frame(mds_result)
mds_plot_data$partner <- pivot_data_shrunk$partner  

# Step 5: Use the first MDS dimension (V1) to assign colors (more similar partners get similar colors)
Plot_05sim=ggplot(mds_plot_data, aes(x = V1, y = V2)) +  
  geom_point(size = 3, aes(color = V1)) +  
  geom_text_repel(
    aes(label = partner), 
    size = 3,
    fontface="bold",
    box.padding=unit(0.5,"lines"),
    point.padding=unit(0.3,"lines"),
    segment.color="grey80",
    segment.size=.5,
    max.overlaps=Inf
  ) +
  scale_color_viridis(option = "C") +  
  labs(title = NULL, x = NULL, y = NULL) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = "white"), # Set background to transparent
    legend.position="none",
    panel.grid=element_blank(),
    axis.text.x=element_blank(),
    axis.ticks.x=element_blank(),
    axis.text.y=element_blank(),
    axis.title.x=element_blank(),
    axis.title.y=element_blank()

    )  
ggsave(paste0(output_dir, "Plot_05 Similarity.jpeg"), plot = Plot_05sim,bg = "white", width = 26, height = 12)


file.copy(paste0(output_dir, "Plot_05.jpeg"), paste0(target_dir, "Plot_05.jpeg"), overwrite = TRUE)
file.copy(paste0(output_dir, "Plot_05 Similarity.jpeg"), paste0(target_dir, "Plot_05-Similarity.jpeg"), overwrite = TRUE) # WordPress renamed the file.

}
