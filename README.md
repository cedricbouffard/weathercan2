# weathercan2 - Complete Package Summary

## Installation

```r
devtools::install_github("cedricbouffard/weathercan2")
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



## Acknowledgments

- Inspired by original [`weathercan`](https://github.com/ropensci/weathercan) package
- Weather data from Environment and Climate Change Canada (ECCC)
- API access via [MSC GeoMet](https://eccc-msc.github.io/open-data/msc-geomet/readme_en/)

---

**Package is fully functional and production-ready!** 🎉

Download Canadian weather data easily using the MSC GeoMet API.
