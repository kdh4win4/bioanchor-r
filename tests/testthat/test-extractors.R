test_that("extract_metadata works with posterior draws", {
  skip_if_not_installed("posterior")
  library(posterior)

  draws <- example_draws("eight_schools")
  meta <- extract_metadata(draws, model_name = "test_eight_schools")

  expect_s3_class(meta, "bioanchor_metadata")
  expect_equal(meta$model_name, "test_eight_schools")
  expect_equal(meta$backend, "posterior")
  expect_true(!is.null(meta$timestamp))
  expect_true(!is.null(meta$diagnostics$rhat))
  expect_true(!is.null(meta$diagnostics$ess_bulk))
  expect_true(is.data.frame(meta$summary))
})

test_that("extract_metadata includes extra metadata", {
  skip_if_not_installed("posterior")
  library(posterior)

  draws <- example_draws("eight_schools")
  meta <- extract_metadata(draws, extra = list(author = "test", project = "demo"))

  expect_equal(meta$extra$author, "test")
  expect_equal(meta$extra$project, "demo")
})

test_that("extract_metadata errors on unsupported objects", {
  expect_error(
    extract_metadata(data.frame(x = 1:5)),
    "Cannot detect MCMC backend"
  )
})

test_that("validate_metadata catches missing fields", {
  bad_meta <- structure(list(model_name = "x"), class = "bioanchor_metadata")
  expect_error(validate_metadata(bad_meta), "missing required fields")
})
