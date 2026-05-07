test_that("mock_uploader returns expected structure", {
  skip_if_not_installed("posterior")
  library(posterior)

  draws <- example_draws("eight_schools")
  meta <- extract_metadata(draws, model_name = "mock_test")
  result <- mock_uploader(meta)

  expect_true(grepl("^mock_", result$tx_id))
  expect_true(grepl("ar-io.dev", result$url))
  expect_true(result$payload_size > 0)
  expect_true(result$mock)
})

test_that("mock_uploader rejects non-metadata objects", {
  expect_error(mock_uploader(list(x = 1)), "bioanchor_metadata")
})

test_that("archive_mcmc works end-to-end with mock", {
  skip_if_not_installed("posterior")
  library(posterior)

  draws <- example_draws("eight_schools")
  result <- archive_mcmc(draws, model_name = "e2e_test")

  expect_s3_class(result$metadata, "bioanchor_metadata")
  expect_true(grepl("^mock_", result$upload$tx_id))
})

test_that("metadata_to_json produces valid JSON", {
  skip_if_not_installed("posterior")
  library(posterior)

  draws <- example_draws("eight_schools")
  meta <- extract_metadata(draws, model_name = "json_test")
  json_str <- bioanchor:::metadata_to_json(meta)

  parsed <- jsonlite::fromJSON(json_str)
  expect_equal(parsed$model_name, "json_test")
  expect_equal(parsed$backend, "posterior")
})
