get_installed_packages <-
        function() {
                return(installed.packages()[,"Package"])
        }

load_packages <-
        function(package_names) {
                
                packages_to_install <- package_names[!(package_names %in% get_installed_packages())]
                
                if (length(packages_to_install)) {
                        install.packages(packages_to_install, dependencies = TRUE, verbose = FALSE)
                }
                
                suppressMessages(lapply(package_names, require, character.only = TRUE, quietly = TRUE))
        }
