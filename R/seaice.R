#' Sea ice concentration data
#'
#' `read_south_seaice` for the southern hemisphere
#' `read_north_seaice`  for the northern hemisphere
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
#' @importFrom dplyr distinct filter transmute mutate
#' @importFrom raster extent raster projection projection<- setZ stack crop
#' @importFrom stringr str_detect str_sub str_replace
#' @export
#' @examples
#' # w <- sp::spTransform(wrld_simpl, projection(read_north_seaice()))
#' #image(read_north_seaice("2017-01-01"), col = viridis::viridis(100), asp = 1)
#' #plot(w, add = T)
#' #image(read_north_seaice(latest = T), col = viridis::viridis(100), asp = 1)
#' #plot(w, add = T)
read_north_seaice <- function(date, latest = TRUE, ...) {
  files <- seaice_files_list()
  datadir <- get_local_file_root()
  if (nrow(files) < 1) {
    test <- yesno::yesno(sprintf("no seaice files available, \ndownload and install files to: \n%s?", datadir))
    if (test) run_bb_sync()
  }
 files <- filter(files, str_detect(.data$fullname, "sidads"))
  files <- filter(files, str_detect(.data$fullname, "bin$"))
  files <- filter(files, str_detect(.data$fullname, "v1.1") | str_detect(.data$fullname, "f18_nrt"))
  files <- filter(files, str_detect(.data$fullname, "north"))
  files <- filter(files, str_detect(.data$fullname, "nsidc0051_gsfc_nasateam_seaice.*daily") |
                          str_detect(.data$fullname, "nsidc0081_nrt_nasateam_seaice"))
  files <-
    mutate(files, date = as.POSIXct(as.Date(str_sub(basename(.data$fullname), 4, 11), "%Y%m%d"),
                                           tz = "GMT"))
  rng <- as.character(range(files$date))

  if (latest) {
    files <- tail(files, 1)
    date <- files$date
  }
  if (!latest && is.missing(date)) {
    files <- head(files, 1)
    date <- files$date
  } else {
    date <- as.POSIXct(date, tz = "GMT")
  }

  files <- files[findInterval(date, files$date), ]
  files <- distinct(files)
  if (nrow(files) < 1) stop(sprintf("input date doesn't match any available files %s", paste(rng, collapse = ":")))
  read_nsidc_internal(files, hemisphere = "north", rescale = TRUE, setNA = TRUE, xylim = NULL)
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
  local_file_root
}


read_nsidc_internal <- function(files, hemisphere, rescale, setNA, xylim = NULL,  ...) {
  ## check that files are available
  ## NSIDC projection and grid size for the Southern Hemisphere
  prj  <- "+proj=stere +lat_0=-90 +lat_ts=-70 +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs "
  if(hemisphere == "north") prj <-    "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +a=6378273 +b=6356889.449 +units=m +no_defs"
  nsidcdims <- if (hemisphere == "south") c(332L, 316L) else c(448L, 304L)
  ext <- if (hemisphere == "south") c(-3950000, 3950000, -3950000, 4350000) else c(-3837500, 3762500, -5362500, 5837500)
  res <-  c(25000, 25000)
  rtemplate <- raster(extent(ext), nrows =  nsidcdims[1L], ncols = nsidcdims[2L], crs = prj)
  ## process xylim
  cropit <- FALSE
  if (!is.null(xylim)) {
    cropit <- TRUE
    cropext <- extent(xylim)
  }

  nfiles <- nrow(files)
  r <- vector("list", nfiles)

  fname <- files$fullname
  r <- vector("list", length(fname))
  for (ifile in seq_len(nfiles)) {

    con <- file(fname[ifile], open = "rb")
    trash <- readBin(con, "integer", size = 1, n = 300)
    dat <- readBin(con, "integer", size = 1, n = prod(nsidcdims), endian = "little", signed = FALSE)
    close(con)
    r100 <- dat > 250
    #r0 <- dat < 1
    if (rescale) {
      dat <- dat/2.5  ## rescale back to 100
    }
    if (setNA) {
      dat[r100] <- NA
      ##dat[r0] <- NA
    }

    # 251  Circular mask used in the Arctic to cover the irregularly-shaped data gap around the pole (caused by the orbit inclination and instrument swath)
    # 252	Unused
    # 253	Coastlines
    # 254	Superimposed land mask
    # 255	Missing data
    #
    ## ratify if neither rescale nor setNA set

    r0 <- raster(t(matrix(dat, nsidcdims[1])), template = rtemplate)
    if (!setNA && !rescale) {
      ##r <- ratify(r)
      rat <- data.frame(ID = 0:255, icecover = c(0:250, "ArcticMask", "Unused", "Coastlines", "LandMask", "Missing"),
                        code = 0:255, stringsAsFactors = FALSE)
      levels(r0) <- rat
    }


    if (cropit) r0 <- crop(r0, cropext)
    r[[ifile]] <- r0
  }
  r <- stack(r)

  projection(r) <- prj
  names(r) <- basename(files$fullname)
  r <- setZ(r, files$date)

  r

}
