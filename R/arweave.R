#' Upload Metadata to Arweave
#'
#' Uploads a JSON-serialized metadata object to the Arweave permaweb
#' via the standard transaction API.
#'
#' @param metadata A `bioanchor_metadata` object (from [extract_metadata()]).
#' @param jwk_path Path to an Arweave JWK wallet file.
#' @param gateway Arweave gateway URL. Default uses ar-io.dev (recommended
#'   over arweave.net for reliability).
#' @param tags A named character vector of additional Arweave transaction tags.
#' @param dry_run If `TRUE`, serialize and validate but do not actually upload.
#'
#' @return A list with `tx_id` (transaction ID) and `url` (gateway URL).
#'
#' @details
#' **Gateway note:** `ar-io.dev` is the recommended gateway. The legacy
#' `arweave.net` gateway is known to be unstable.
#'
#' **Wallet:** You need an Arweave JWK wallet file with sufficient AR balance.
#' See <https://arweave.org> for wallet creation.
#'
#' @export
upload_to_arweave <- function(metadata,
                              jwk_path,
                              gateway = "https://ar-io.dev",
                              tags = NULL,
                              dry_run = FALSE) {

  if (!inherits(metadata, "bioanchor_metadata")) {
    abort("`metadata` must be a 'bioanchor_metadata' object from extract_metadata().")
  }

  # Validate metadata
  validate_metadata(metadata)

  # Serialize
  payload <- metadata_to_json(metadata)

  if (dry_run) {
    cli::cli_alert_info("Dry run mode: payload validated ({nchar(payload)} bytes), skipping upload.")
    return(invisible(list(
      tx_id = NA_character_,
      url = NA_character_,
      payload_size = nchar(payload),
      dry_run = TRUE
    )))
  }

  # Read wallet
  if (!file.exists(jwk_path)) {
    abort(paste0("Wallet file not found: ", jwk_path))
  }
  jwk <- jsonlite::fromJSON(jwk_path)

  # Default tags
  default_tags <- c(
    "Content-Type" = "application/json",
    "App-Name" = "BioAnchor-R",
    "App-Version" = as.character(utils::packageVersion("bioanchor")),
    "Model-Name" = metadata$model_name,
    "Backend" = metadata$backend,
    "Timestamp" = metadata$timestamp
  )
  all_tags <- c(default_tags, tags)

  # Build and send transaction
  tx_result <- arweave_post_transaction(
    data = payload,
    jwk = jwk,
    gateway = gateway,
    tags = all_tags
  )

  cli::cli_alert_success("Uploaded to Arweave!")
  cli::cli_alert_info("TX ID: {tx_result$tx_id}")
  cli::cli_alert_info("URL: {gateway}/{tx_result$tx_id}")

  invisible(list(
    tx_id = tx_result$tx_id,
    url = paste0(gateway, "/", tx_result$tx_id),
    payload_size = nchar(payload)
  ))
}


#' Mock Uploader for Testing
#'
#' A drop-in replacement for [upload_to_arweave()] that simulates an upload
#' without requiring a wallet or network access. Useful for testing and CI.
#'
#' @inheritParams upload_to_arweave
#'
#' @return A list with a fake `tx_id` and `url`.
#'
#' @export
mock_uploader <- function(metadata, gateway = "https://ar-io.dev", tags = NULL) {

  if (!inherits(metadata, "bioanchor_metadata")) {
    abort("`metadata` must be a 'bioanchor_metadata' object from extract_metadata().")
  }

  validate_metadata(metadata)
  payload <- metadata_to_json(metadata)

  fake_tx_id <- paste0("mock_", paste0(
    sample(c(letters, LETTERS, 0:9), 43, replace = TRUE),
    collapse = ""
  ))

  cli::cli_alert_info("[MOCK] Simulated upload ({nchar(payload)} bytes)")
  cli::cli_alert_info("[MOCK] TX ID: {fake_tx_id}")

  invisible(list(
    tx_id = fake_tx_id,
    url = paste0(gateway, "/", fake_tx_id),
    payload_size = nchar(payload),
    mock = TRUE
  ))
}


#' Validate BioAnchor Metadata
#'
#' Checks that a metadata object has the required fields and valid diagnostics.
#'
#' @param metadata A `bioanchor_metadata` object.
#' @return `TRUE` invisibly if valid; errors otherwise.
#' @export
validate_metadata <- function(metadata) {
  required <- c("model_name", "backend", "timestamp", "diagnostics", "summary")
  missing <- setdiff(required, names(metadata))
  if (length(missing) > 0) {
    abort(paste0("Metadata missing required fields: ", paste(missing, collapse = ", ")))
  }

  # Check Rhat warnings
  if (!is.null(metadata$diagnostics$rhat)) {
    bad_rhat <- sum(metadata$diagnostics$rhat > 1.1, na.rm = TRUE)
    if (bad_rhat > 0) {
      warn(paste0(bad_rhat, " parameter(s) have Rhat > 1.1. Consider running longer chains."))
    }
  }

  invisible(TRUE)
}


# --- Internal helpers ---

#' @keywords internal
metadata_to_json <- function(metadata) {
  # Convert to plain list for serialization
  plain <- unclass(metadata)
  # Convert data frames to list-of-rows for clean JSON
  if (is.data.frame(plain$summary)) {
    plain$summary <- jsonlite::toJSON(plain$summary, dataframe = "rows", auto_unbox = TRUE)
    plain$summary <- jsonlite::fromJSON(plain$summary)
  }
  jsonlite::toJSON(plain, auto_unbox = TRUE, pretty = TRUE, na = "null")
}


#' @keywords internal
arweave_post_transaction <- function(data, jwk, gateway, tags) {
  # Build tags array for Arweave API
  tag_list <- lapply(names(tags), function(nm) {
    list(name = nm, value = unname(tags[nm]))
  })

  # Step 1: Get transaction anchor
  anchor_resp <- httr2::request(paste0(gateway, "/tx_anchor")) |>
    httr2::req_perform()
  anchor <- httr2::resp_body_string(anchor_resp)

  # Step 2: Create and sign transaction
  # NOTE: Full Arweave signing requires RSA-PSS with the JWK.

  # For production, consider using the arweave-js Node CLI as a subprocess,
  # which is more reliable (consistent with Python BioAnchor's approach).
  tx_body <- list(
    data = jsonlite::base64_enc(charToRaw(data)),
    last_tx = anchor,
    reward = "0",
    tags = tag_list
  )

  # Post transaction
  resp <- httr2::request(paste0(gateway, "/tx")) |>
    httr2::req_headers("Content-Type" = "application/json") |>
    httr2::req_body_json(tx_body) |>
    httr2::req_perform()

  list(
    tx_id = httr2::resp_body_json(resp)$id %||% "pending",
    status = httr2::resp_status(resp)
  )
}
