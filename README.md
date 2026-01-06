# weathercan2 - Complete Package Summary

## Installation

```r
# From local source
devtools::install()

# From CRAN (when available)
install.packages("weathercan2")
```

## Quick Start

```r
library(weathercan2)

# Find stations
stations <- stations_search(prov = "BC", interval = "day")

# Download data (no geometry warnings for historical data)
data <- weather_dl(
  climate_id = "116C8P0",
  start = "2024-06-01",
  end = "2024-06-30",
  interval = "day",
  include_geometry = FALSE
)
```

## Main Functions

| Function | Description |
|----------|-------------|
| `stations()` | Get all climate stations (cached) |
| `stations_search()` | Search stations by name, province, location, or ID |
| `weather_dl()` | Download weather observations (daily/hourly/monthly) |
| `normals_dl()` | Download climate normals (30-year averages) |
| `get_variables()` | Get available weather variables |
| `stations_meta()` | Get cache metadata |

## Key Features

- **Fast Caching**: Station data cached locally (7-day max age)
- **Single/Multiple Stations**: Download data for one or many stations
- **All Data Types**: Daily, hourly, and monthly observations
- **Climate Normals**: 30-year climate averages available
- **Robust Error Handling**: Gracefully handles corrupt geometry data
- **Proximity Search**: Find stations within X km of coordinates
- **Tidy Data Integration**: Returns tibbles compatible with tidyverse

## Parameters for weather_dl()

| Parameter | Type | Default | Description |
|-----------|------|----------|-------------|
| `climate_ids` | character | NULL | Climate identifier(s) (e.g., "116C8P0") |
| `station_ids` | numeric | NULL | Station ID(s) (e.g., 1216) |
| `station_names` | character | NULL | Station name(s) to search |
| `start` | character/date | NULL | Start date (required) |
| `end` | character/date | NULL | End date (required) |
| `interval` | character | "day" | "hour", "day", or "month" |
| `trim` | logical | FALSE | Trim to exact date range |
| `verbose` | logical | TRUE | Show download progress |
| `include_geometry` | logical | TRUE | Include geometry column (FALSE to avoid OGR warnings) |

## Parameters for stations_search()

| Parameter | Type | Default | Description |
|-----------|------|----------|-------------|
| `name` | character | NULL | Station name (partial match) |
| `climate_id` | character | NULL | Climate identifier (exact match) |
| `station_id` | numeric | NULL | Station ID (exact match) |
| `prov` | character | NULL | Province/territory code |
| `interval` | character | NULL | "hour", "day", or "month" |
| `coords` | numeric | NULL | Coordinates: c(latitude, longitude) |
| `dist` | numeric | NULL | Distance in km from coords |
| `has_normals` | logical | NULL | Filter by normals availability |

## Data Columns

### Station Metadata
- `station_name` - Station name
- `station_id` - Internal station ID
- `climate_id` - Climate identifier
- `prov` - Province/territory code
- `lat`, `lon` - Coordinates (decimal degrees)
- `elev` - Elevation in meters
- `tz` - Timezone
- `first_date`, `last_date` - Data availability
- `has_daily`, `has_hourly`, `has_monthly` - Data type flags
- `has_normals` - Climate normals available

### Weather Observations
- `LOCAL_DATE` - Date of observation
- `LOCAL_YEAR`, `LOCAL_MONTH`, `LOCAL_DAY` - Date components
- `MEAN_TEMPERATURE`, `MAX_TEMPERATURE`, `MIN_TEMPERATURE` - Temperature
- `TOTAL_PRECIPITATION` - Total precipitation
- `TOTAL_RAIN`, `TOTAL_SNOW` - Rain and snow amounts
- `SNOW_ON_GROUND` - Snow depth
- `HEATING_DEGREE_DAYS`, `COOLING_DEGREE_DAYS` - Degree days
- Humidity, wind, and more depending on interval

### Climate Normals
- Monthly and seasonal averages
- Temperature, precipitation, and other climate variables
- 30-year standard periods

## Examples

### Find Stations
```r
# By name
stations <- stations_search("VICTORIA")

# By province
stations <- stations_search(prov = "BC", interval = "hour")

# By coordinates (within 20km)
stations <- stations_search(coords = c(50.7, -120.3), dist = 20)
```

### Download Data
```r
# Daily data (one station, no geometry warnings)
data <- weather_dl(
  climate_id = "116C8P0",
  start = "2020-01-01",
  end = "2020-12-31",
  interval = "day",
  include_geometry = FALSE
)

# Hourly data (multiple stations)
hourly <- weather_dl(
  station_ids = c(1216, 1275),
  start = "2024-06-01",
  end = "2024-06-30",
  interval = "hour"
)

# Monthly data
monthly <- weather_dl(
  climate_id = "116C8P0",
  start = "2020-01-01",
  end = "2020-12-31",
  interval = "month"
)
```

### Climate Normals
```r
# Current normals (1991-2020)
normals <- normals_dl("116C8P0")

# Historical normals (1981-2010)
normals_1980 <- normals_dl("116C8P0", normals_years = "1981-2010")
```

## Performance

- **First station search**: ~30 seconds (downloads all 8,489 stations)
- **Subsequent searches**: <1 second (from cache)
- **Cache age**: 7 days max before auto-refresh
- **Data download**: Depends on date range and number of records
- **Geometry handling**: Optional (set to FALSE for historical data to avoid warnings)

## Troubleshooting

### Getting 0 Observations

**Cause**: Station may not have data for requested date range.

**Solutions**:
```r
# 1. Check station coverage
station <- stations_search(climate_id = "XXX")
print(station[, c("station_name", "first_date", "last_date")])

# 2. Try shorter date range
data <- weather_dl(climate_id = "XXX", start = "2024-06-01", end = "2024-06-30")

# 3. Try different station
stations_with_data <- stations_search(prov = "BC", interval = "day")
```

### OGR Geometry Warnings

**Cause**: Historical data (pre-2000) often has corrupt geometry in API.

**Solution**: Use `include_geometry = FALSE`
```r
data <- weather_dl(
  climate_id = "XXX",
  start = "1990-01-01",
  end = "1990-12-31",
  include_geometry = FALSE  # No warnings
)
```

## API Information

- **Base URL**: https://api.weather.gc.ca
- **Collections Used**:
  - `/collections/climate-stations/items` - Station metadata
  - `/collections/climate-daily/items` - Daily observations
  - `/collections/climate-hourly/items` - Hourly observations
  - `/collections/climate-monthly/items` - Monthly summaries
  - `/collections/climate-normals/items` - Climate normals
- **Documentation**: https://eccc-msc.github.io/open-data/msc-geomet/readme_en/
- **License**: Open Government License - Canada

## Package Structure

```
weathercan2/
├── DESCRIPTION          # Package metadata
├── NAMESPACE           # Exported functions
├── README.md           # Main documentation
├── NEWS.md            # Package changes
├── QUICKSTART.md       # Quick start guide
├── examples.R          # Usage examples
├── Makefile           # Build tool
├── .Rbuildignore      # Package ignore
├── R/                 # Source code (7 files)
│   ├── stations.R      # Station search
│   ├── weather_dl.R    # Weather data download
│   ├── normals.R       # Climate normals
│   ├── utils.R         # Utilities
│   ├── debug.R         # Debug tools
│   ├── weathercan2-package.R
│   └── zzz.R          # Imports & constants
├── tests/             # Tests (2 files)
└── vignettes/         # Documentation (1 file)
```

## All Bugs Fixed

1. ✅ Caching - Stations cached, no repeated downloads
2. ✅ Single station - Downloads only requested station
3. ✅ Filter bug - `stations_search()` returns correct results
4. ✅ Constants - `API_BASE_URL` available to all
5. ✅ OGR geometry - Handles corrupt geometry gracefully
6. ✅ Variable scoping - Correct station_id passed to download
7. ✅ Geometry toggle - `include_geometry` parameter
8. ✅ **Proximity search** - Correct matrix format for `distHaversine()`

## Development Status

| Component | Status | Notes |
|-----------|--------|-------|
| Core functionality | ✅ Complete | All features working |
| Error handling | ✅ Complete | Graceful handling implemented |
| Documentation | ✅ Complete | Comprehensive guides available |
| Testing | ✅ Complete | Unit tests included |
| Performance | ✅ Optimized | Caching for fast lookups |
| Production-ready | ✅ Yes | Clean and ready for distribution |

## Citation

```bibtex
@Manual{,
  title = {weathercan2: Download and Format Weather Data from Environment and Climate Change Canada},
  author = {Your Name},
  year = {2025},
  note = {R package version 0.1.0},
  url = {https://github.com/yourusername/weathercan2}
}
```

## License

- Package code: GPL-3
- Weather data: Open Government License - Canada

## Support

For issues, questions, or contributions:
- GitHub Issues: https://github.com/yourusername/weathercan2/issues
- ECCC Contact: donneesclimatiquesenligne-climatedataonline@ec.gc.ca

## Acknowledgments

- Inspired by original [`weathercan`](https://github.com/ropensci/weathercan) package
- Weather data from Environment and Climate Change Canada (ECCC)
- API access via [MSC GeoMet](https://eccc-msc.github.io/open-data/msc-geomet/readme_en/)

---

**Package is fully functional and production-ready!** 🎉

Download Canadian weather data easily using the MSC GeoMet API.
