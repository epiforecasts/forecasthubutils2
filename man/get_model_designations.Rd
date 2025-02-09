% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_model_designations.R
\name{get_model_designations}
\alias{get_model_designations}
\title{Get the model designation of each model in a forecast hub}
\usage{
get_model_designations(hub_repo_path)
}
\arguments{
\item{hub_repo_path}{path to the local clone of the forecast repository}
}
\value{
a data frame of each "model", and the corresponding "designation"
}
\description{
Reads the metadata files to extract model_designation field
}
