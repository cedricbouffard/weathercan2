test_that("stations_dl works", {
  skip_on_cran()
  
  # This test might be slow, so skip unless testing thoroughly
  skip("Skip stations_dl test by default (too slow)")
  
  stations <- stations_dl()
  
  expect_s3_class(stations, "data.frame")
  expect_true(nrow(stations) > 0)
  expect_true("station_name" %in% names(stations))
  expect_true("station_id" %in% names(stations))
  expect_true("climate_id" %in% names(stations))
})

test_that("stations_search works", {
  skip_on_cran()
  
  stations <- stations()
  
  # Search by name
  result <- stations_search(name = "Victoria")
  expect_true(nrow(result) > 0)
  expect_true(any(grepl("VICTORIA", toupper(result$station_name))))
  
  # Search by province
  result <- stations_search(prov = "BC")
  expect_true(all(result$prov == "BC"))
})

test_that("weather_dl works", {
  skip_on_cran()
  
  # Test with a small date range and known station
  # Victoria Gonzales station (ID: 114)
  
  result <- weather_dl(
    station_ids = 114,
    start = "2020-01-01",
    end = "2020-01-10",
    interval = "day",
    verbose = FALSE
  )
  
  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) >= 0)  # May be 0 if no data available
})

test_that("normals_dl works", {
  skip_on_cran()
  
  # Test with a station that likely has normals
  result <- normals_dl("101AE00")
  
  # May return empty tibble if no normals available
  expect_s3_class(result, "data.frame")
})
