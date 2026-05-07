# Extract MCMC Metadata from Fitted Model Objects

Extracts convergence diagnostics, posterior summaries, and model
specifications from various MCMC backends (Stan, brms, coda).

## Usage

``` r
extract_metadata(fit, model_name = NULL, extra = list())
```

## Arguments

- fit:

  A fitted model object. Supported classes:

  - `stanfit` (from rstan)

  - `brmsfit` (from brms)

  - `mcmc.list` (from coda)

  - `draws_array`, `draws_df`, `draws_list` (from posterior)

- model_name:

  Optional character string naming the model.

- extra:

  A named list of additional metadata to include.

## Value

A list with class `"bioanchor_metadata"` containing:

- `model_name`: character

- `backend`: character (e.g., "rstan", "brms", "coda", "posterior")

- `timestamp`: ISO 8601 timestamp

- `diagnostics`: list with Rhat, ESS, divergences (where available)

- `summary`: posterior summary data frame

- `model_info`: model-specific information

- `extra`: user-supplied metadata

## Examples

``` r
# With a posterior draws object:
library(posterior)
#> This is posterior version 1.7.0
#> 
#> Attaching package: ‘posterior’
#> The following objects are masked from ‘package:stats’:
#> 
#>     mad, sd, var
#> The following objects are masked from ‘package:base’:
#> 
#>     %in%, match
draws <- example_draws("eight_schools")
meta <- extract_metadata(draws, model_name = "eight_schools")
```
