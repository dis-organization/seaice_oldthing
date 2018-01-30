#' Sea ice concentration data
#'
#' `read_south_seaice` will read daily sea ice concentration data for the southern hemisphere
#' `read_north_seaice` will read daily sea ice concentration data for the northern hemisphere
#' @param date input date
#' @param latest return the latest day available, otherwise the earliest available
#' @param ... ignored
#'
#' @return RasterLayer
#' @export
#'
#' @examples
#' \dontrun{
#' if (seaice_files_available()) {
#' read_south_seaice(latest = FALSE)
#' }
#' }
read_south_seaice <- function(date, latest = TRUE, ...) {
  ## probably should be monthly/daily distinction
  stop("not yet implemented")
}
#' @name read_south_seaice
#' @export
read_north_seaice <- function(date, latest = TRUE, ...) {
  stop("not yet implemented")
}

seaice_files_available <- function(...) {
  nrow(seaice_files_list()) > 0
}

seaice_files_list <- function(...) {
  datadir <- get_local_file_root()
  tibble::tibble(fullname =  list.files(datadir, full.names = TRUE, recursive = TRUE))
}
get_local_file_root <- function(...) {
  local_file_root <- getOption("seaice_local_file_root")
  if (is.null(local_file_root)) {
    local_file_root <- rappdirs::user_data_dir(appname = "seaice")
  }
}
