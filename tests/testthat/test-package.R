context("Test package loading")

test_that("package can be loaded", {
  expect_true(requireNamespace("weathercan2", quietly = TRUE))
})

test_that("required packages are available", {
  expect_s3_class(weathercan2:::API_BASE_URL, "character")
})
