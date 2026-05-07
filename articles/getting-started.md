# Getting Started with BioAnchor

## Overview

`bioanchor` lets you permanently archive MCMC analysis metadata on the
[Arweave](https://arweave.org) permaweb. It extracts convergence
diagnostics, posterior summaries, and model specifications from fitted
model objects, then uploads them as structured JSON.

## Basic Workflow

``` r
library(bioanchor)
library(posterior)
#> This is posterior version 1.7.0
#> 
#> Attaching package: 'posterior'
#> The following objects are masked from 'package:stats':
#> 
#>     mad, sd, var
#> The following objects are masked from 'package:base':
#> 
#>     %in%, match

# Use the built-in eight schools example
draws <- example_draws("eight_schools")

# Extract metadata
meta <- extract_metadata(draws, model_name = "eight_schools_demo")
print(meta)
#> 
#> ── BioAnchor Metadata ──────────────────────────────────────────────────────────
#> ℹ Model: eight_schools_demo
#> ℹ Backend: posterior
#> ℹ Timestamp: 2026-05-07T16:17:50+0000
#> ✔ Max Rhat: 1.0235 (converged)
#> ℹ Parameters: 10
```

## Archiving with Mock Uploader

For testing (no Arweave wallet required):

``` r
result <- archive_mcmc(draws, model_name = "eight_schools_demo")
#> 
#> ── BioAnchor: Archiving MCMC Results ──
#> 
#> ℹ Extracting metadata...
#> 
#> ── BioAnchor Metadata ──────────────────────────────────────────────────────────
#> ℹ Model: eight_schools_demo
#> ℹ Backend: posterior
#> ℹ Timestamp: 2026-05-07T16:17:50+0000
#> ✔ Max Rhat: 1.0235 (converged)
#> ℹ Parameters: 10
#> ℹ No wallet provided, using mock uploader.
#> ℹ [MOCK] Simulated upload (3110 bytes)
#> ℹ [MOCK] TX ID: mock_SwlKLUUEdLieexomb92Q9QeuR8HfdVHIyvQgF0fivjF

# Inspect the result
result$upload$tx_id
#> [1] "mock_SwlKLUUEdLieexomb92Q9QeuR8HfdVHIyvQgF0fivjF"
result$upload$payload_size
#> [1] 3110
```

## Adding Custom Metadata

``` r
meta <- extract_metadata(draws,
  model_name = "eight_schools",
  extra = list(
    author = "Dohoon Kim",
    affiliation = "Promptgenix LLC",
    project = "Hierarchical model comparison",
    doi = "10.5281/zenodo.19709077"
  )
)
```

## Real Arweave Upload

When you have an Arweave JWK wallet:

``` r
result <- archive_mcmc(draws,
  model_name = "eight_schools",
  jwk_path = "~/.arweave/wallet.json",
  extra = list(author = "Your Name")
)

# Access the permanent URL
browseURL(result$upload$url)
```
