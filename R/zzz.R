#' @importFrom httr GET content status_code
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows filter mutate select %>%
#' @importFrom jsonlite fromJSON
#' @importFrom lubridate year
#' @importFrom sf st_as_sfc
#' @importFrom stringr str_detect
#' @importFrom geosphere distHaversine
#' @importFrom rlang sym
NULL

#' Base URL for MSC GeoMet API
API_BASE_URL <- "https://api.weather.gc.ca"

#' Cache file for stations data
STATIONS_CACHE_FILE <- "stations_cache.rds"

STATIONS_CACHE_MAX_AGE <- 7  # days
