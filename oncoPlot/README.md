oncoPlot. 
This package contains functions that plots the Kaplan-Meier Survival Curves and Time-to-Treatment histograms as seen at the OHDSI Symposium in September 2019.

Requirements. 
Connection details for OMOP CDM version 5. In the examples below, the details are in the .Renviron file to ensure connection details remain private in public repos. To learn more about this methodology, please visit https://csgillespie.github.io/efficientR/3-3-r-startup.html#renviron
R version 3.5.0 or newer

Installing oncoPlot. 
install.packages("devtools")
library(devtools)
devtools::install_github("OHDSI/OncologyWG/oncoPlot")


Survival Curve
oncoPlot::plot_survival(dbms = "postgresql",
                        user = Sys.getenv("username"),
                        password = Sys.getenv("password"),
                        server = Sys.getenv("server"),
                        schema = schema,
                        port = port)
                        
Time To Treatment Histogram
oncoPlot::plot_time_to_rx_hist(dbms = "postgresql",
                        user = Sys.getenv("username"),
                        password = Sys.getenv("password"),
                        server = Sys.getenv("server"),
                        schema = schema,
                        port = port)
