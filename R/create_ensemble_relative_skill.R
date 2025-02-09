#' Ensemble by relative skill
#'
#' @inheritParams create_ensemble_average
#' @param evaluation_date which date should be used to measure model
#' performance? A corresponding file containing evaluations is expected in \code{evaluation/evaluation-{evaluation_date}.csv}
#' @param continuous_weeks include only forecasts with a history of evaluation
#' @param by_horizon weight using relative skill by horizon, rather than average
#' @param skill the relative skill score to be used for creating the ensemble; a column called \code{rel_{skill}} is expected to exist in the evaluation csv file
#' @param by_horizon whether to create the ensemble separately for each horizon (default: FALSE)
#' @param history the number of recent weeks of history to consider in determining the weights; either "All" or a number of weeks
#' @inheritParams weighted_average
#' @inheritParams use_ensemble_criteria
#' @param verbose Logical determining whether diagnostic messages should
#' be printed while running (defaults to `FALSE`).
#'
#' @details
#' Ensemble = sum of forecast values weighted by the inverse of relative skill
#' Weights are by model, horizon, target, location
#' i.e. not weighted by quantile
#'
#' @importFrom vroom vroom
#' @importFrom here here
#' @importFrom dplyr select filter group_by %>% summarise mutate across all_of select_at n .data
#'
#' @autoglobal
#'
#' @export
create_ensemble_relative_skill <- function(forecasts,
                                           evaluation_date,
                                           continuous_weeks = 4,
                                           average = "mean",
                                           skill = "wis",
                                           history = "All",
                                           by_horizon = FALSE,
                                           eval_dir = here::here("evaluation", "weekly-summary"),
                                           return_criteria = FALSE,
                                           verbose = FALSE) {

# Get evaluation ----------------------------------------------------------

  col_name <- paste("rel", skill, sep = "_")
  if (missing(evaluation_date)) {
    evaluation_date <- max(forecasts$forecast_date)
  }

  evaluation <- try(suppressMessages(
    vroom(here(eval_dir, paste0("evaluation-", evaluation_date, ".csv")))))
  # evaluation error catching
  if ("try-error" %in% class(evaluation)) {
    stop(paste0("Evaluation not found for ", evaluation_date))
  }
  if (!(col_name %in% names(evaluation))) {
    stop(paste("Evaluation does not include relative", skill))
  } else {
    evaluation <- evaluation %>%
      mutate(relative_skill = as.numeric(.data[[col_name]]))
  }

  if ("weeks_included" %in% colnames(evaluation)) {
    evaluation <- evaluation %>%
      filter(weeks_included == history) %>%
      select(-weeks_included)
  }

  if (verbose) {message(paste0("Relative skill evaluation as of ",
                               evaluation_date))}
  # include only models with forecasts,
  #   with evaluation for >= x weeks
  skill <- evaluation %>%
    select(model, continuous_weeks, target_variable,
           horizon, location, relative_skill) %>%
    filter(model %in% forecasts$model &
             continuous_weeks >= !!continuous_weeks &
             !is.na(relative_skill))

  # Average skill over all horizons (default)
  if (!by_horizon) {
    skill <- skill %>%
      group_by(model, location, target_variable) %>%
      summarise(relative_skill = mean(relative_skill, na.rm = TRUE),
                .groups = "drop")
  }

# Find weights ---------------------------------------------
  # Take inverse of relative skill
  skill <- skill %>%
    mutate(inv_skill = ifelse(relative_skill > 0,
                              1/relative_skill, 0))

  # Weights for each model, by location, target (and horizon)
  groups <- c("target_variable", "location")
  if (by_horizon) {
    groups <- c(groups, "horizon")
  }

  weights <- skill %>%
    group_by(across(all_of(groups))) %>%
    mutate(sum_inv_skill = sum(inv_skill, na.rm = TRUE),
           weight = inv_skill / sum_inv_skill) %>%
    select_at(c("model", groups, "weight"))

  if (verbose) {message(paste0("Included ",
                               length(unique(weights$model)), " models"))}

# Sum weights for ensemble ------------------------------------------------
  join <- c(groups, "model")
  forecast_skill <- left_join(forecasts, weights, by = join) %>%
    filter(!is.na(weight))

  # Take sum of weighted values
  weighted_ensemble <- forecast_skill %>%
    group_by(quantile, target_variable, location, horizon) %>%
    summarise(value = weighted_average(x = value, weights = weight,
                                       average = average),
              n_models = n(),
              .groups = "drop")

  if (return_criteria) {
    return(list("weights" = weights,
                "ensemble" = weighted_ensemble))
  }

  return(weighted_ensemble)
}
