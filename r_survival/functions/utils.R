get_installed_packages <-
        function() {
                return(installed.packages()[,"Package"])
        }

load_packages <-
        function() {
                package_names <- c("tidyverse", "survival", "survminer")
                packages_to_install <- package_names[!(package_names %in% get_installed_packages())]
                
                if (length(packages_to_install)) {
                        install.packages(packages_to_install, dependencies = TRUE, verbose = FALSE)
                }
                
                sapply(1:length(package_names), function(i) require(package_names[i], character.only = TRUE, quietly = TRUE))
        }

try_catch_error_as_na <-
        function(expr) {
                tryCatch(expr, error = function(e) NA)
        }