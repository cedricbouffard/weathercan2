#' Download climate normals
#'
#' Download climate normals for a station. Climate normals are 30-year averages
#' of climate variables.
#'
#' @param climate_id Character. Climate identifier (e.g., "101AE00").
#' @param normals_years Character. "current" for current normals (1991-2020),
#'   or specific year range (e.g., "1981-2010").
#' @return A tibble of climate normals
#' @export
#'
#' @examples
#' \dontrun{
#' normals_dl("101AE00")
#' normals_dl("101AE00", normals_years = "1981-2010")
#' }
normals_dl <- function(climate_id, normals_years = "current") {
  
  if (is.null(climate_id)) {
    stop("Must specify a climate_id")
  }
  
  # Get station info
  stn_info <- stations_search(climate_id = climate_id)
  
  if (nrow(stn_info) == 0) {
    stop(sprintf("Climate ID %s not found", climate_id))
  }
  
  if (!stn_info$has_normals[1]) {
    warning(sprintf("Station %s does not have normals data available", climate_id))
    return(tibble::tibble())
  }
  
  # Determine normals collection based on year range
  collection <- switch(normals_years,
                       "current" = "climate-normals",
                       "1991-2020" = "climate-normals",
                       "1981-2010" = "climate-normals-1981-2010",
                       "1971-2000" = "climate-normals-1971-2000",
                       stop("normals_years must be 'current', '1981-2010', or '1971-2000'"))
  
  url <- paste0(
    API_BASE_URL, "/collections/", collection, "/items",
    "?f=json",
    "&CLIMATE_IDENTIFIER=", climate_id
  )
  
  response <- httr::GET(url)
  
  if (httr::status_code(response) != 200) {
    warning(sprintf("Error downloading normals for station %s: HTTP %s",
                   climate_id, httr::status_code(response)))
    return(tibble::tibble())
  }
  
  content <- httr::content(response, as = "parsed", type = "application/json")
  
  if (length(content$features) == 0) {
    warning(sprintf("No normals data found for station %s", climate_id))
    return(tibble::tibble())
  }
  
  normals_data <- dplyr::bind_rows(lapply(content$features, function(f) {
    props <- f$properties
    
    tibble::tibble(
      station_name = stn_info$station_name[1],
      station_id = stn_info$station_id[1],
      climate_id = climate_id,
      prov = stn_info$prov[1],
      lat = stn_info$lat[1],
      lon = stn_info$lon[1],
      elev = stn_info$elev[1],
      normals_period = normals_years
    ) |>
      dplyr::bind_rows(
        # Add all properties from the API
        dplyr::as_tibble(t(props))
      )
  }))
  
  normals_data
}
