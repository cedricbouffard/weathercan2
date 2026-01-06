#' Download weather data for stations
#'
#' Download historical weather data for one or more stations for a specified date range.
#' Data can be retrieved at hourly, daily, or monthly intervals.
#'
#' @param station_ids Numeric vector. Station ID(s) to download data for.
#' @param climate_ids Character vector. Climate identifier(s) (e.g., "101AE00").
#' @param station_names Character vector. Station name(s) to search for.
#' @param start Character or Date. Start date (e.g., "2018-01-01").
#' @param end Character or Date. End date (e.g., "2018-12-31").
#' @param interval Character. Time interval: "hour", "day", or "month". Default is "day".
#' @param trim Logical. If TRUE, trim to exact date range. Default is FALSE.
#' @param verbose Logical. If TRUE, print download progress. Default is TRUE.
#' @return A tibble of weather data
#' @export
#'
#' @examples
#' \dontrun{
#' # Download daily data for a station
#' weather_dl(climate_id = "101AE00", start = "2020-01-01", end = "2020-12-31")
#'
#' # Download hourly data for multiple stations
#' weather_dl(station_ids = c(2, 3), start = "2020-06-01", end = "2020-06-30", 
#'             interval = "hour")
#'
#' # Download without geometry (faster, no warnings)
#' weather_dl(climate_id = "101AE00", start = "2020-01-01", end = "2020-12-31"
#')
#' }
weather_dl <- function(station_ids = NULL, climate_ids = NULL, station_names = NULL,
                      start = NULL, end = NULL, interval = "day",
                      trim = FALSE, verbose = TRUE) {
  
  # Validate interval
  if (!interval %in% c("hour", "day", "month")) {
    stop("interval must be 'hour', 'day', or 'month'")
  }
  
  # Get station IDs from various inputs
  if (!is.null(station_names)) {
    found_stations <- lapply(station_names, function(name) {
      stations_search(name = name, interval = interval)
    })
    found_stations <- dplyr::bind_rows(found_stations)
    
    if (nrow(found_stations) == 0) {
      stop("No stations found with the specified name(s)")
    }
    
    station_ids <- unique(found_stations$station_id)
  } else if (!is.null(climate_ids)) {
    # When climate_ids are provided, get matching station_ids directly
    # Get all stations once
    all_stations <- stations()
    
    # Filter by climate_id(s)
    station_ids <- unique(
      all_stations |> 
        dplyr::filter(climate_id %in% toupper(climate_ids)) |> 
        dplyr::pull(station_id)
    )
    
    if (length(station_ids) == 0) {
      stop(sprintf("No stations found with climate_id(s): %s", 
                 paste(climate_ids, collapse = ", ")))
    }
  } else if (is.null(station_ids)) {
    stop("Must specify station_ids, climate_ids, or station_names")
  }
  
  # Validate date range
  if (is.null(start) || is.null(end)) {
    stop("Must specify both start and end dates")
  }
  
  start_date <- as.Date(start)
  end_date <- as.Date(end)
  
  if (end_date < start_date) {
    stop("end date must be after start date")
  }
  
  # Determine collection based on interval
  collection <- switch(interval,
                       "hour" = "climate-hourly",
                       "day" = "climate-daily",
                       "month" = "climate-monthly")
  
    all_data <- tibble::tibble()
  
  for (stn_id in station_ids) {
    if (verbose) {
      message(sprintf("Downloading data for station %s (%s)...", stn_id, interval))
    }
    
    station_data <- download_station_data(
      stn_id, collection, start_date, end_date, verbose
    )
    
    if (nrow(station_data) > 0) {
      all_data <- dplyr::bind_rows(all_data, station_data)
    }
    
  }
  
  # Trim to exact date range if requested
  if (trim && nrow(all_data) > 0) {
    if ("LOCAL_DATE" %in% names(all_data)) {
      all_data <- all_data |> 
        dplyr::filter(as.Date(LOCAL_DATE) >= start_date &
                      as.Date(LOCAL_DATE) <= end_date)
    } else if ("LOCAL_YEAR" %in% names(all_data)) {
      all_data <- all_data |> 
        dplyr::filter(LOCAL_YEAR >= lubridate::year(start_date) &
                      LOCAL_YEAR <= lubridate::year(end_date))
    }
  }
  
  if (verbose) {
    message(sprintf("Downloaded %d observations total.", nrow(all_data)))
  }
  
  all_data
}

#' Download data for a single station
#'
#' @keywords internal
download_station_data <- function(stn_id, collection, start_date, end_date, verbose) {
  
  all_observations <- tibble::tibble()
  
  offset <- 0
  limit <- 1000
  has_more <- TRUE
  
  # Get climate_id and station info for this station directly from cached stations
  all_stations <- stations()
  stn_info <- all_stations |>  dplyr::filter(station_id == stn_id)
  
  if (nrow(stn_info) == 0) {
    warning(sprintf("Station ID %s not found", stn_id))
    return(tibble::tibble())
  }
  
  climate_id <- stn_info$climate_id[1]
  station_name <- stn_info$station_name[1]
  prov <- stn_info$prov[1]
  lat <- stn_info$lat[1]
  lon <- stn_info$lon[1]
  elev <- stn_info$elev[1]
  tz <- stn_info$tz[1]
  
  # Build datetime range
  start_str <- format(start_date, "%Y-%m-%d")
  end_str <- format(end_date, "%Y-%m-%d")
  
  while (has_more) {
    url <- paste0(
      API_BASE_URL, "/collections/", collection, "/items",
      "?f=json",
      "&CLIMATE_IDENTIFIER=", climate_id,
      "&datetime=", start_str, "/", end_str,
      "&limit=", limit,
      "&offset=", offset
    )
    
    response <- httr::GET(url)
    
    if (httr::status_code(response) != 200) {
      warning(sprintf("Error downloading data for station %s: HTTP %s",
                     stn_id, httr::status_code(response)))
      break
    }
    
    content <- httr::content(response, as = "parsed", type = "application/json")
    
    if (length(content$features) == 0) {
      has_more <- FALSE
      break
    }
    
    observations <- dplyr::bind_rows(lapply(content$features, function(f) {
      props <- f$properties
      
      # Extract common properties

      obs <- tibble::tibble(
        station_name = station_name,
        station_id = stn_id,
        climate_id = climate_id,
        prov = prov,
        lat = lat,
        lon = lon,
        elev = elev,
        tz = tz # Can be NULL if corrupt or disabled
      )
      
      # Add observation-specific properties
      for (prop_name in names(props)) {
        if (!prop_name %in% names(obs)) {
          obs[[prop_name]] <- props[[prop_name]]
        }
      }
      
      obs
    }))
    
    all_observations <- dplyr::bind_rows(all_observations, observations)
    
    if (verbose) {
      message(sprintf("  Downloaded %d observations...", nrow(all_observations)))
    }
    
    if (nrow(observations) < limit) {
      has_more <- FALSE
    } else {
      offset <- offset + limit
    }
  }
  
  all_observations
}
