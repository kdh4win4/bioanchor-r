# bioanchor <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/bioanchor)](https://CRAN.R-project.org/package=bioanchor)
[![R-CMD-check](https://github.com/kdh4win4/bioanchor-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kdh4win4/bioanchor-r/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**Permanent Archiving of MCMC Analysis Metadata on Arweave**

`bioanchor` bridges Bayesian MCMC analysis in R with [Arweave](https://arweave.org) decentralized storage, enabling permanent, tamper-proof archiving of analysis metadata — convergence diagnostics, posterior summaries, and model specifications.

This is the R companion to [BioAnchor for Python](https://github.com/kdh4win4/bioanchor) (`pip install bioanchor`).

## Installation

```r
# From GitHub (development version)
remotes::install_github("kdh4win4/bioanchor-r")

# From CRAN (when available)
# install.packages("bioanchor")
```

## Quick Start

```r
library(bioanchor)
library(posterior)

# Fit your model (using any MCMC backend)
draws <- example_draws("eight_schools")

# One-step archive (uses mock uploader without a wallet)
result <- archive_mcmc(draws, model_name = "eight_schools")

# With a real Arweave wallet
result <- archive_mcmc(draws,
  model_name = "eight_schools",
  jwk_path = "~/.arweave/wallet.json"
)

# View the archived metadata
print(result$metadata)

# Access the Arweave transaction
result$upload$tx_id
result$upload$url
```

## Supported MCMC Backends

| Backend | Object Class | Package |
|---------|-------------|---------|
| Stan | `stanfit` | `rstan` |
| brms | `brmsfit` | `brms` |
| CODA | `mcmc.list` | `coda` |
| posterior | `draws_*` | `posterior` |

## Step-by-Step Usage

```r
# Step 1: Extract metadata
meta <- extract_metadata(fit, model_name = "my_model",
  extra = list(author = "Dohoon Kim", project = "IC50 analysis"))

# Step 2: Validate
validate_metadata(meta)

# Step 3: Upload (or mock)
result <- upload_to_arweave(meta, jwk_path = "wallet.json")
# or: result <- mock_uploader(meta)
```

## Gateway Note

This package uses `ar-io.dev` as the default Arweave gateway. The legacy `arweave.net` gateway is known to be unstable. You can specify a custom gateway:

```r
upload_to_arweave(meta, jwk_path = "wallet.json",
  gateway = "https://ar-io.dev")
```

## Related

- [BioAnchor (Python)](https://github.com/kdh4win4/bioanchor) — the original Python implementation
- [Arweave](https://arweave.org) — permanent decentralized storage
- [posterior](https://mc-stan.org/posterior/) — unified interface for MCMC draws in R

## Citation

If you use `bioanchor` in your research, please cite:

```
Kim, D. (2026). BioAnchor: Permanent archiving of MCMC analysis metadata
on the Arweave blockchain. Zenodo. https://doi.org/10.5281/zenodo.19709077
```

## License

MIT
