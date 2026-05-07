#' @keywords internal
"_PACKAGE"

#' Archive MCMC Results to Arweave (One-Step Workflow)
#'
#' A convenience wrapper that extracts metadata from a fitted MCMC object
#' and uploads it to Arweave in a single call.
#'
#' @param fit A fitted model object (stanfit, brmsfit, mcmc.list, or posterior draws).
#' @param model_name Optional character string naming the model.
#' @param jwk_path Path to Arweave JWK wallet file. If `NULL`, uses [mock_uploader()].
#' @param gateway Arweave gateway URL.
#' @param tags Additional Arweave transaction tags (named character vector).
#' @param extra Additional metadata to include (named list).
#' @param dry_run If `TRUE`, validate without uploading.
#'
#' @return A list with `metadata` (bioanchor_metadata object) and `upload`
#'   (upload result with tx_id and url).
#'
#' @export
#' @examples
#' \dontrun{
#' library(posterior)
#' draws <- example_draws("eight_schools")
#'
#' # Mock upload (no wallet needed)
#' result <- archive_mcmc(draws, model_name = "eight_schools")
#' print(result$metadata)
#'
#' # Real upload
#' result <- archive_mcmc(draws,
#'   model_name = "eight_schools",
#'   jwk_path = "~/.arweave/wallet.json"
#' )
#' }
archive_mcmc <- function(fit,
                         model_name = NULL,
                         jwk_path = NULL,
                         gateway = "https://ar-io.dev",
                         tags = NULL,
                         extra = list(),
                         dry_run = FALSE) {

  cli::cli_h2("BioAnchor: Archiving MCMC Results")

  # Step 1: Extract
  cli::cli_alert_info("Extracting metadata...")
  metadata <- extract_metadata(fit, model_name = model_name, extra = extra)
  print(metadata)

  # Step 2: Upload
  if (is.null(jwk_path)) {
    cli::cli_alert_info("No wallet provided, using mock uploader.")
    upload_result <- mock_uploader(metadata, gateway = gateway, tags = tags)
  } else if (dry_run) {
    upload_result <- upload_to_arweave(metadata, jwk_path = jwk_path,
                                       gateway = gateway, tags = tags,
                                       dry_run = TRUE)
  } else {
    upload_result <- upload_to_arweave(metadata, jwk_path = jwk_path,
                                       gateway = gateway, tags = tags)
  }

  invisible(list(
    metadata = metadata,
    upload = upload_result
  ))
}
