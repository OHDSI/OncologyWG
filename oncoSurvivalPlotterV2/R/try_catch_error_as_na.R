#' Wrapper that returns NA if evaluating expression returns an error
#' @param expr expression

try_catch_error_as_na <-
function(expr) {
                tryCatch(expr, error = function(e) NA)
        }
