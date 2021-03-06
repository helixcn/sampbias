% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/map_bias.R
\name{map_bias}
\alias{map_bias}
\title{Mapping Projected Bias Effects}
\usage{
map_bias(x, gaz = NULL, sealine = TRUE, logtransform = TRUE)
}
\arguments{
\item{x}{a raster stack as generate by \code{\link{project_bias}}}

\item{gaz}{a list of SpatialObjects, to be printed on the maps.  Should be
the same objects provided to \code{calculate_bias} when creating the Object.
If \code{gaz} is not supplied, the sampbias package standard gazetteers are
used.}

\item{sealine}{logical. Should the sealine be added to the plots? Default is
to TRUE.}

\item{logtransform}{logical. IF TRUE, the bias projections are logtransformed. Default is TRUE.}
}
\value{
A series of R plots based on ggplot2.
}
\description{
A plotting function to visualize the bias effects calculated using \code{\link{calculate_bias}}
and projected using \code{\link{project_bias}}.
}
\examples{

#simulate data
occ <- data.frame(species = rep(sample(x = LETTERS, size = 5), times = 10),
                  decimalLongitude = runif(n = 50, min = -5, max = 5),
                  decimalLatitude = runif(n = 50, min = -4, max = 4))


#create point gazetteer
pts <- data.frame(long = runif(n = 5, min = -5, max = 5),
                  lat = runif(n = 5, min = -4, max = 4),
                  dat = rep("A", 5))
pts <- SpatialPointsDataFrame(coords = pts[,1:2], data = data.frame(pts[,3]))

lin <- data.frame(long = seq(-5, 5, by = 1),
                  lat = rep(2, times = 11))
lin <- SpatialLinesDataFrame(sl = SpatialLines(list(Lines(Line(lin), ID="B1"))),
                             data = data.frame("B", row.names = "B1"))

gaz <- list(lines.strucutre = lin, point.structure = pts)

out <- calculate_bias(x = occ, gaz = gaz, terrestrial = FALSE)
proj <- project_bias(out)
map_bias(proj)

}
\seealso{
\code{\link{calculate_bias}}, \code{\link{project_bias}}
}
\keyword{methods}
