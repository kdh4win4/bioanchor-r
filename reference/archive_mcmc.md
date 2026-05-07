# Archive MCMC Results to Arweave (One-Step Workflow)

A convenience wrapper that extracts metadata from a fitted MCMC object
and uploads it to Arweave in a single call.

## Usage

``` r
archive_mcmc(
  fit,
  model_name = NULL,
  jwk_path = NULL,
  gateway = "https://ar-io.dev",
  tags = NULL,
  extra = list(),
  dry_run = FALSE
)
```

## Arguments

- fit:

  A fitted model object (stanfit, brmsfit, mcmc.list, or posterior
  draws).

- model_name:

  Optional character string naming the model.

- jwk_path:

  Path to Arweave JWK wallet file. If `NULL`, uses
  [`mock_uploader()`](https://kdh4win4.github.io/bioanchor-r/reference/mock_uploader.md).

- gateway:

  Arweave gateway URL.

- tags:

  Additional Arweave transaction tags (named character vector).

- extra:

  Additional metadata to include (named list).

- dry_run:

  If `TRUE`, validate without uploading.

## Value

A list with `metadata` (bioanchor_metadata object) and `upload` (upload
result with tx_id and url).

## Examples

``` r
if (FALSE) { # \dontrun{
library(posterior)
draws <- example_draws("eight_schools")

# Mock upload (no wallet needed)
result <- archive_mcmc(draws, model_name = "eight_schools")
print(result$metadata)

# Real upload
result <- archive_mcmc(draws,
  model_name = "eight_schools",
  jwk_path = "~/.arweave/wallet.json"
)
} # }
```
