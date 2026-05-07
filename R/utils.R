# Null-coalescing operator (for R < 4.4 compatibility)
`%||%` <- function(x, y) if (is.null(x)) y else x

#' @importFrom rlang abort warn inform %||%
#' @importFrom cli cli_h1 cli_h2 cli_alert_success cli_alert_info cli_alert_warning
#' @importFrom jsonlite toJSON fromJSON base64_enc
#' @importFrom utils packageVersion
#' @keywords internal
#' @name bioanchor-imports
#' @title Internal imports
NULL
