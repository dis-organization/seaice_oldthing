library(magick)
library(seaice)
library(raster)
dates <- seq(as.Date("2016-04-01"), as.Date("2018-02-11"), by = "6 days")
## first collect all the base images
images <- do.call(c, purrr::map(dates,
                                function(date) {
  x <- read_north_seaice(date)[[1]]
  image_read(as.raster(as.matrix(x) / 100))
}))

## now set up the stuff to overlay
## image_draw allows adding to a plot in data coords
## and we can capture from the Viewer
images_map <- vector("list", length(images))
dummy <- read_north_seaice(dates[1])
data("wrld_simpl", package = "maptools")
d <- sp::spTransform(subset(wrld_simpl, coordinates(wrld_simpl)[,2] > 30), projection(dummy))
d$color <- sample(rainbow(nrow(d)))

for (i in seq_along(images_map)) {
  image_draw(images[i], xlim = c(xmin(dummy), xmax(dummy)), ylim = c(ymin(dummy), ymax(dummy)))
  plot(d, add = TRUE, col = c("grey", "lightgrey"))
  images_map[[i]] <- image_capture()
  dev.off()
}

image_animate(do.call(c, images_map))


