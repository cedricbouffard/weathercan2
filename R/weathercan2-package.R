#' weathercan2: Download and Format Weather Data from ECCC
#'
#' An R package for downloading historical weather data from Environment and Climate
#' Change Canada (ECCC) using the MSC GeoMet API. This package provides functions
#' to search for weather stations and download daily, hourly, and monthly weather
#' observations.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{stations}} - Get all climate stations
#'   \item \code{\link{stations_search}} - Search for stations by name, location, or ID
#'   \item \code{\link{weather_dl}} - Download weather data for stations
#'   \item \code{\link{normals_dl}} - Download climate normals
#' }
#'
#' @section API:
#' This package uses the MSC GeoMet API (https://api.weather.gc.ca/) which provides
#' access to Environment and Climate Change Canada weather and climate data.
#'
#' @docType package
#' @name weathercan2
NULL
