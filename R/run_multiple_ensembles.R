#' Runs and saves past ensembles for specified methods/dates.
#'
#' Wrapper around [run_ensemble()] that allows multiple methods/forecast dates.
#'
#' @param forecast_dates Dates vector
#' @param methods character vector of method/s supported in [run_ensemble()]
#'   (as in the named folders of code/ensemble/forecasts)
#' @param ... arguments passed to [run_ensemble()]
#'
#' @return a list of ensembles with forecasts, method, forecast date, criteria
#'
#' @importFrom purrr map2
#'
#' @export

run_multiple_ensembles <- function(forecast_dates,
                                   methods,
                                   ...) {

  # Match methods and dates
  forecast_dates <- as.Date(forecast_dates)
  dates <- rep(forecast_dates, each = length(methods))
  methods <- rep(methods, length(forecast_dates))

  # Run ensembles
  ensembles <- map2(methods,
                    dates,
                    run_ensemble,
                    ...)

  # Add descriptive name
  names(ensembles) <- paste(methods, dates, sep = "-")

  return(ensembles)

}
