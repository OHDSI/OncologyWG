# README  
## Survival and Time To Treatment Curves Using OMOP Data  
OVERVIEW: this subdirectory provides the R scripts that executes Kaplan-Meier curves and Time To Treatment histograms using one R dataframe object that contains a single variable that defines each cohort. At this time, cohorts cannot be defined by greater than one grouping variable. For example, the provided simulated 1000 patient test_data.RData file produces outputs comparing disease metastasis status ("metastatic", "nonmetastatic," and "unknown") and greater granularity would need to be pursued in the input data itself.  

DEPENDENCIES (_utils.R & plot_functions.R_)  
The dependencies will be installed and/or sourced on first execution of either plot functions.  

REQUIREMENTS:  
One R dataframe object derived from the accompanying SQL script for querying your OMOP instance for the data of interest. The final input dataframe object should contain the following fields: survival time in months, death occurrence as numeric binary (0 or 1), time from diagnosis to treatment in days, and a cohort variable. Assigning specific data classes is unnecessary because the script has data class conversion built-in.  

CAVEATS:  
-Input data may not have "cohort_definition" as a column name. It will break the code due to duplicate column names.  
-Label text scales may be off due to the size of your input data since the functions were designed based on a smaller sample of 1000 simulated patients.  
-A `survival_object` R object will be created in the global environment after executing the _plot_survival_ function on your data. This was a bandaid solution to this function in the interest of time.  

PROCEDURE:  
_execute_test_plot.R_ serves as both a test for plotting functions as well as template for using your own data for analysis. Note that these functions are based on Tidyverse evaluation and column names are entered unquoted. The file "test_data.RData" is a 1000-patient dataset that was simulated on normal distribution curves. Successful execution is confirmed when both plot functions are able to print graphs in your console using "test_data.RData".  

After confirming that the functions are plotting appropriately, the functions can be used on any R dataframe object following the constraints highlighted under REQUIREMENTS. Images may be exported via "Plots>Save" option in R Studio.  

ACCESSORIES:  
_accessory_eval.R_ returns a dataframe object of median survival time or survival curve p-value should you desire the additional supportive analysis.  

Happy Plotting!  


