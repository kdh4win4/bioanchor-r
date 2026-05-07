# Mock Uploader for Testing

A drop-in replacement for
[`upload_to_arweave()`](https://kdh4win4.github.io/bioanchor-r/reference/upload_to_arweave.md)
that simulates an upload without requiring a wallet or network access.
Useful for testing and CI.

## Usage

``` r
mock_uploader(metadata, gateway = "https://ar-io.dev", tags = NULL)
```

## Arguments

- metadata:

  A `bioanchor_metadata` object (from
  [`extract_metadata()`](https://kdh4win4.github.io/bioanchor-r/reference/extract_metadata.md)).

- gateway:

  Arweave gateway URL. Default uses ar-io.dev (recommended over
  arweave.net for reliability).

- tags:

  A named character vector of additional Arweave transaction tags.

## Value

A list with a fake `tx_id` and `url`.
