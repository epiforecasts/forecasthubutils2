#' Format ensemble
#'
#' Converts a quantile-only ensemble based on [covidHubUtils::load_forecasts()]
#' to standardised submission format
#'
#' @param ensemble Data.frame containing the ensemble forecast
#' @param forecast_date The date at which this forecast has been established
#' @param temporal_resolution The temporal resolution of the forecast (defaults
#' to `"wk"`)
#'
#' @details
#' Steps:
#' Creates "target" variable
#'
#' @importFrom dplyr ungroup mutate
#' @importFrom lubridate wday
#'
#' @autoglobal
#'
#' @export
#

format_ensemble <- function(ensemble,
                            forecast_date,
                            temporal_resolution = "wk") {

  # FIXME: this should be here. There is no reason we should get grouped
  # ensemble in the first place.
  ensemble <- ungroup(ensemble)

  # Add target end date
  if (!"target_end_date" %in% names(ensemble)) {
    # TODO: use the day defined in the config file for this
    ensemble <- ensemble %>%
      mutate(target_end_date = ((forecast_date +
                                   (7 - wday(forecast_date)) - 7 ) +
                                (7 * horizon)))
  }

  # Add type
  if (!"type" %in% names(ensemble)) {
    ensemble <- ensemble %>%
      mutate(type = "quantile")
  }

  # Set target and model
  ensemble <- ensemble %>%
    mutate(forecast_date = !!forecast_date,
           target = paste(horizon, temporal_resolution,
                          "ahead", target_variable)) %>%
    # Keep only standard columns
    select(forecast_date, target, target_end_date,
           location, type, quantile, value)

  # round
  ensemble <- ensemble %>%
    mutate(value = round(value))

  # Add point forecasts
  ensemble_with_point <- add_point_forecasts(ensemble)

  return(ensemble_with_point)
}
