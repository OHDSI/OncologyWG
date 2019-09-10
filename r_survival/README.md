This subdir creates a simple simulated data set for survival analysis. 
Executing 00_setup.R, 01_a_load_simulated_data.R, and 02_analyze_simulated_data.R will produce Kaplan Meier and Cox Proportional
Hazards based on the configurations in the config.R file. The naming convention for the data defaults to `DATA_00` currently.

01_b_load_data_from_omop.R scripts the joins if working with OMOP tables, with the R Data Object Name assuming the names of the tables
isolated for this analysis.
