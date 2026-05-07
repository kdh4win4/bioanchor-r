#' Extract MCMC Metadata from Fitted Model Objects
#'
#' Extracts convergence diagnostics, posterior summaries, and model
#' specifications from various MCMC backends (Stan, brms, coda).
#'
#' @param fit A fitted model object. Supported classes:
#'   - `stanfit` (from rstan)
#'   - `brmsfit` (from brms)
#'   - `mcmc.list` (from coda)
#'   - `draws_array`, `draws_df`, `draws_list` (from posterior)
#' @param model_name Optional character string naming the model.
#' @param extra A named list of additional metadata to include.
#'
#' @return A list with class `"bioanchor_metadata"` containing:
#'   - `model_name`: character
#'   - `backend`: character (e.g., "rstan", "brms", "coda", "posterior")
#'   - `timestamp`: ISO 8601 timestamp
#'   - `diagnostics`: list with Rhat, ESS, divergences (where available)
#'   - `summary`: posterior summary data frame
#'   - `model_info`: model-specific information
#'   - `extra`: user-supplied metadata
#'
#' @export
#' @examples
#' # With a posterior draws object:
#' library(posterior)
#' draws <- example_draws("eight_schools")
#' meta <- extract_metadata(draws, model_name = "eight_schools")
extract_metadata <- function(fit, model_name = NULL, extra = list()) {
  backend <- detect_backend(fit)
  model_name <- model_name %||% paste0("model_", format(Sys.time(), "%Y%m%d_%H%M%S"))

  extractor <- switch(backend,
    "rstan"     = extract_stanfit,
    "brms"      = extract_brmsfit,
    "coda"      = extract_mcmclist,
    "posterior" = extract_draws,
    abort(paste0("Unsupported object class: ", paste(class(fit), collapse = ", ")))
  )

  metadata <- extractor(fit)
  metadata$model_name <- model_name
  metadata$backend <- backend
  metadata$timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  metadata$r_version <- paste0(R.version$major, ".", R.version$minor)
  metadata$bioanchor_version <- as.character(utils::packageVersion("bioanchor"))
  metadata$extra <- extra

  structure(metadata, class = "bioanchor_metadata")
}


#' @keywords internal
detect_backend <- function(fit) {
  cls <- class(fit)
  if ("stanfit" %in% cls)    return("rstan")
  if ("brmsfit" %in% cls)    return("brms")
  if ("mcmc.list" %in% cls)  return("coda")
  # posterior draws formats
  draws_classes <- c("draws_array", "draws_df", "draws_list",
                     "draws_matrix", "draws_rvars")
  if (any(draws_classes %in% cls)) return("posterior")
  abort(paste0("Cannot detect MCMC backend for class: ", paste(cls, collapse = ", ")))
}


# --- Backend-specific extractors ---

#' @keywords internal
extract_stanfit <- function(fit) {
  if (!requireNamespace("rstan", quietly = TRUE)) {
    abort("Package 'rstan' is required to extract metadata from stanfit objects.")
  }

  summ <- rstan::summary(fit)$summary
  sampler_params <- rstan::get_sampler_params(fit, inc_warmup = FALSE)

  n_divergent <- sum(sapply(sampler_params, function(x) sum(x[, "divergent__"])))
  max_treedepth <- max(sapply(sampler_params, function(x) max(x[, "treedepth__"])))

  list(
    diagnostics = list(
      rhat = summ[, "Rhat"],
      ess_bulk = summ[, "n_eff"],
      n_divergent = n_divergent,
      max_treedepth = max_treedepth,
      n_chains = fit@sim$chains,
      n_iter = fit@sim$iter,
      n_warmup = fit@sim$warmup
    ),
    summary = as.data.frame(summ),
    model_info = list(
      model_code = rstan::get_stancode(fit)
    )
  )
}


#' @keywords internal
extract_brmsfit <- function(fit) {
  if (!requireNamespace("brms", quietly = TRUE)) {
    abort("Package 'brms' is required to extract metadata from brmsfit objects.")
  }

  summ <- summary(fit)
  # brms uses rstan under the hood
  stanfit <- fit$fit
  meta <- extract_stanfit(stanfit)
  meta$model_info$formula <- deparse(fit$formula$formula)
  meta$model_info$family <- fit$family$family
  meta
}


#' @keywords internal
extract_mcmclist <- function(fit) {
  if (!requireNamespace("coda", quietly = TRUE)) {
    abort("Package 'coda' is required to extract metadata from mcmc.list objects.")
  }

  summ <- summary(fit)
  gelman <- tryCatch(
    coda::gelman.diag(fit, multivariate = FALSE),
    error = function(e) NULL
  )
  ess <- coda::effectiveSize(fit)

  rhat_vals <- if (!is.null(gelman)) gelman$psrf[, "Point est."] else NULL

  list(
    diagnostics = list(
      rhat = rhat_vals,
      ess_bulk = ess,
      n_chains = length(fit),
      n_iter = nrow(fit[[1]])
    ),
    summary = data.frame(
      mean = summ$statistics[, "Mean"],
      sd = summ$statistics[, "SD"],
      q2.5 = summ$quantiles[, "2.5%"],
      q25 = summ$quantiles[, "25%"],
      q50 = summ$quantiles[, "50%"],
      q75 = summ$quantiles[, "75%"],
      q97.5 = summ$quantiles[, "97.5%"]
    ),
    model_info = list()
  )
}


#' @keywords internal
extract_draws <- function(fit) {
  summ <- posterior::summarise_draws(fit)

  list(
    diagnostics = list(
      rhat = stats::setNames(summ$rhat, summ$variable),
      ess_bulk = stats::setNames(summ$ess_bulk, summ$variable),
      ess_tail = stats::setNames(summ$ess_tail, summ$variable),
      n_variables = nrow(summ)
    ),
    summary = as.data.frame(summ),
    model_info = list(
      draws_class = class(fit)[1]
    )
  )
}


#' Print method for bioanchor_metadata
#' @param x A `bioanchor_metadata` object.
#' @param ... Additional arguments (ignored).
#' @return `x` invisibly.
#' @export
print.bioanchor_metadata <- function(x, ...) {
  cli::cli_h1("BioAnchor Metadata")
  cli::cli_alert_info("Model: {x$model_name}")
  cli::cli_alert_info("Backend: {x$backend}")
  cli::cli_alert_info("Timestamp: {x$timestamp}")

  if (!is.null(x$diagnostics$rhat)) {
    max_rhat <- max(x$diagnostics$rhat, na.rm = TRUE)
    if (max_rhat > 1.05) {
      cli::cli_alert_warning("Max Rhat: {round(max_rhat, 4)} (convergence issues detected)")
    } else {
      cli::cli_alert_success("Max Rhat: {round(max_rhat, 4)} (converged)")
    }
  }

  if (!is.null(x$diagnostics$n_divergent) && x$diagnostics$n_divergent > 0) {
    cli::cli_alert_warning("Divergent transitions: {x$diagnostics$n_divergent}")
  }

  n_params <- nrow(x$summary)
  if (!is.null(n_params)) {
    cli::cli_alert_info("Parameters: {n_params}")
  }

  invisible(x)
}
