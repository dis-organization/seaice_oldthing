library(furrr)
plan(multicore)
s <- icefiles()
n <- icefiles(hemisphere = "north")
south <- future_map(s$fullname, readBin, what = "raw", n = 332 * 316)
north <- future_map(n$fullname, readBin, what = "raw", n = 448 * 304)
ice <- tibble::tibble(date = s$date, south = south, north = north)
saveRDS(ice, "data-raw/ice.rds")

## TODO: implement read since a year ago (make sure we get updates)
##   smarter, keep the file name too and invalidate on that

archivefile <- "ice_data-raw.tar.gz"
unlink(archivefile)
system(glue::glue("tar cvzf {archivefile} data-raw"))
library(piggyback)
pb_upload(archivefile, tag = "v0.1.0")


