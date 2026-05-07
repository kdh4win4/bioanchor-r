# Upload Metadata to Arweave

Uploads a JSON-serialized metadata object to the Arweave permaweb via
the standard transaction API.

## Usage

``` r
upload_to_arweave(
  metadata,
  jwk_path,
  gateway = "https://ar-io.dev",
  tags = NULL,
  dry_run = FALSE
)
```

## Arguments

- metadata:

  A `bioanchor_metadata` object (from
  [`extract_metadata()`](https://kdh4win4.github.io/bioanchor-r/reference/extract_metadata.md)).

- jwk_path:

  Path to an Arweave JWK wallet file.

- gateway:

  Arweave gateway URL. Default uses ar-io.dev (recommended over
  arweave.net for reliability).

- tags:

  A named character vector of additional Arweave transaction tags.

- dry_run:

  If `TRUE`, serialize and validate but do not actually upload.

## Value

A list with `tx_id` (transaction ID) and `url` (gateway URL).

## Details

**Gateway note:** `ar-io.dev` is the recommended gateway. The legacy
`arweave.net` gateway is known to be unstable.

**Wallet:** You need an Arweave JWK wallet file with sufficient AR
balance. See <https://arweave.org> for wallet creation.
