

#' Get all climate stations
#'
#' Returns a tibble of all climate stations from the MSC GeoMet API.
#' This includes station metadata such as location, elevation, and time period coverage.
#'
#' @return A tibble of climate stations with columns: station_name, station_id, 
#'   climate_id, prov, lat, lon, elev, tz, station_type, first_date, last_date, 
#'   has_daily, has_hourly, has_monthly, has_normals
#' @export
#'
#' @examples
#' \dontrun{
#' stations()
#' }
stations <- function() {
  stations_dl()
}

#' Download and cache all climate stations
#'
#' Downloads all climate stations from the MSC GeoMet API and returns as a tibble.
#' This function may take some time to complete as it retrieves all available stations.
#'
#' @param refresh Logical. If TRUE, re-download the stations from the API.
#'   Default is FALSE, which returns cached data if available.
#' @param cache_file Character. Path to cache file. Default is "stations_cache.rds".
#' @param cache_dir Character. Directory to save cache file. Default is NULL (current directory).
#'   Use this to share cache across projects (e.g., cache_dir = "data").
#' @param max_age Numeric. Maximum age of cache in days before refresh. Default is 7.
#' @return A tibble of climate stations
#' @export
#'
#' @examples
#' \dontrun{
#' stations_dl()
#' stations_dl(refresh = TRUE)
#' stations_dl(cache_dir = "data")
#' }
stations_dl <- function(refresh = FALSE, 
                     cache_file = STATIONS_CACHE_FILE,
                     cache_dir = NULL,
                     max_age = STATIONS_CACHE_MAX_AGE) {
   
  # Handle cache directory
  if (!is.null(cache_dir)) {
    # Create directory if it doesn't exist
    if (!dir.exists(cache_dir)) {
      tryCatch(
        dir.create(cache_dir, recursive = TRUE),
        error = function(e) {
          warning(sprintf("Could not create cache directory: %s", e$message))
        }
      )
    }
    cache_path <- file.path(cache_dir, cache_file)
  } else {
    cache_path <- cache_file
  }
  
  # Check if cache exists and is recent
  if (!refresh && file.exists(cache_path)) {
    file_age <- difftime(Sys.time(), file.mtime(cache_path), units = "days")
    if (file_age <= max_age) {
      message(sprintf("Loading stations from cache (%.1f days old)", as.numeric(file_age)))
      return(readRDS(cache_path))
    } else {
      message(sprintf("Cache is %.1f days old (max: %d days). Refreshing...", 
                    as.numeric(file_age), max_age))
    }
  }
  
  all_stations <- tibble::tibble()
  offset <- 0
  limit <- 1000
  has_more <- TRUE

  message("Downloading station data from MSC GeoMet API...")
  
  while (has_more) {
    url <- paste0(
      API_BASE_URL, "/collections/climate-stations/items",
      "?f=json&limit=", limit, "&offset=", offset
    )
    
    response <- httr::GET(url)
    content <- httr::content(response, as = "parsed", type = "application/json")
    
    if (length(content$features) == 0) {
      has_more <- FALSE
      break
    }
    
    stations_batch <- dplyr::bind_rows(lapply(content$features, function(f) {
      props <- f$properties
      
      tibble::tibble(
        station_name = props$STATION_NAME,
        station_id = props$STN_ID,
        climate_id = props$CLIMATE_IDENTIFIER,
        prov = trimws(props$PROV_STATE_TERR_CODE),
        lat = props$LATITUDE / 1e7,
        lon = props$LONGITUDE / 1e7,
        elev = as.numeric(props$ELEVATION),
        tz = props$TIMEZONE,
        station_type = props$STATION_TYPE,
        first_date = props$FIRST_DATE,
        last_date = props$LAST_DATE,
        has_daily = !is.null(props$DLY_FIRST_DATE) && props$DLY_FIRST_DATE != "",
        has_hourly = !is.null(props$HLY_FIRST_DATE) && props$HLY_FIRST_DATE != "",
        has_monthly = !is.null(props$MLY_FIRST_DATE) && props$MLY_FIRST_DATE != "",
        has_normals = props$HAS_NORMALS_DATA == "Y"
      )
    }))
    
    all_stations <- dplyr::bind_rows(all_stations, stations_batch)
    
    message(sprintf("Downloaded %d of %d stations...", nrow(all_stations), content$numberMatched))
    
    # Check if we've downloaded all stations
    if (nrow(all_stations) >= content$numberMatched || length(content$features) == 0) {
      has_more <- FALSE
    } else {
      offset <- offset + limit
    }
  }
  
  message(sprintf("Downloaded %d stations total.", nrow(all_stations)))
  
  # Save to cache
  tryCatch({
    saveRDS(all_stations, cache_path)
    message(sprintf("Saved stations to cache: %s", cache_path))
  }, error = function(e) {
    warning(sprintf("Could not save cache: %s", e$message))
  })
  
  all_stations
}

#' Search for climate stations
#'
#' Search for climate stations by name, coordinates, or province.
#'
#' @param name Character string. Station name to search for (partial match).
#' @param climate_id Character string. Climate identifier (e.g., "101AE00").
#' @param station_id Numeric. Station ID.
#' @param prov Character string. Province/territory code (e.g., "BC", "ON").
#' @param coords Numeric vector of length 2. Coordinates (latitude, longitude).
#' @param dist Numeric. Distance in kilometers from coordinates for proximity search.
#' @param interval Character. Time interval: "hour", "day", or "month".
#' @param normals_years Character. "current" for current normals (1991-2020),
#'   or specific year range (e.g., "1981-2010").
#' @param has_normals Logical. If TRUE, only return stations with normals data.
#' @return A tibble of matching climate stations
#' @export
#'
#' @examples
#' \dontrun{
#' stations_search("Kamloops")
#' stations_search(prov = "BC", interval = "hour")
#' stations_search(coords = c(50.7, -120.3), dist = 20)
#' }
stations_search <- function(name = NULL, climate_id = NULL, station_id = NULL,
                           prov = NULL, coords = NULL, dist = NULL,
                           interval = NULL, normals_years = NULL,
                           has_normals = NULL) {
  
  all_stations <- stations()
  
  # Filter by name
  if (!is.null(name)) {
    all_stations <- all_stations |> 
      dplyr::filter(stringr::str_detect(
        toupper(station_name),
        toupper(name)
      ))
  }
  
  # Filter by climate_id
  if (!is.null(climate_id)) {
    # Handle single climate_id or vector
    climate_ids_upper <- toupper(climate_id)
    all_stations <- all_stations |> 
      dplyr::filter(.env$climate_id %in% climate_ids_upper)
  }
  
  # Filter by station_id
  if (!is.null(station_id)) {
    all_stations <- all_stations |> 
      dplyr::filter(.env$station_id %in% station_id)
  }
  
  # Filter by province
  if (!is.null(prov)) {
    all_stations <- all_stations |> 
      dplyr::filter(!is.na(.env$prov) & .env$prov == trimws(toupper(prov)))
  }
  
  # Filter by interval
  if (!is.null(interval)) {
    has_col <- switch(interval,
                      "hour" = "has_hourly",
                      "day" = "has_daily",
                      "month" = "has_monthly",
                      stop("interval must be 'hour', 'day', or 'month'"))
    
    all_stations <- all_stations |> 
      dplyr::filter(!!rlang::sym(has_col) == TRUE)
  }
  
  # Filter by normals availability
  if (!is.null(has_normals)) {
    all_stations <- all_stations |> 
      dplyr::filter(has_normals == has_normals)
  }
  
  # Filter by distance from coordinates
  if (!is.null(coords)) {
    if (length(coords) != 2) {
      stop("coords must be a numeric vector of length 2: c(latitude, longitude)")
    }
    
    lat <- coords[1]
    lon <- coords[2]
    
    # Create proper coordinate matrix for geosphere
    coords_matrix <- matrix(c(lon, lat), nrow = 1, ncol = 2)
    
    all_stations <- all_stations |> 
      dplyr::mutate(
        distance = geosphere::distHaversine(
          coords_matrix,
          cbind(.env$lon, .env$lat)
        ) / 1000  # Convert to km
      ) |> 
      dplyr::filter(distance <= dist)
  }
    
   
  
  all_stations
}
