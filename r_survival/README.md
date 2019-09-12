## Survival and Time To Treatment Curves Using OMOP Data
OVERVIEW: this subdirectory provides the R scripts that executes Kaplan-Meier curves and Time To Treatment histograms using one R dataframe that contains a single variable that defines each cohort. At this time, cohort definition cannot go beyond a single variable. For example, the provided simulated 1000 patient test_data.RData file produces outputs comparing disease metastasis status ("metastatic", "nonmetastatic," and "unknown") and greater granularity would need to be pursued in the input data itself.

DEPENDENCIES
The dependencies will be installed and/or sourced on first execution of either plot functions.

REQUIREMENTS:
One R dataframe object derived from the accompanying SQL script for querying your OMOP instance for the data of interest. The final input data should contain the following fields: survival time in months, death occurrence as numeric binary (0 or 1), time from diagnosis to treatment in days, and a cohort variable. Assigning specific data classes is unnecessary because the script has data class conversion built in.

TEST EXECUTION: _execute_test_plot.R_
Test data and a test script are included in the repo. The scripts used to plot the data are based on Tidyverse evaluation and column names are entered unquoted. If plots are produced at each script execution, you are ready to run the script on your data using this script as a template.


