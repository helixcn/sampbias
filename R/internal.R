#'@importFrom raster rasterize
#'@importFrom stats dexp dpois rnorm runif

#Occurrence raster
.OccRast <- function(x, ras){
  rast <- raster::rasterize(x, ras, fun = "count")
  return(rast)
}

#get number of decimal places
.DecimalPlaces <- function(x) {
  if ((x %% 1) != 0) {
    nchar(strsplit(sub('0+$', '', as.character(x)), ".", fixed = TRUE)[[1]][[2]])
  } else {
    return(0)
  }
}

# get_lambda_ij_old <- function(q, w, X) {
#   if (class(X) == "numeric") {
#     return(q * exp(-w * X))
#   } else {
#     return(q * exp(-apply(FUN = sum, w * X, 2)))
#   }
# }


get_lambda_ij <- function(q, w, X) {
  if (class(X) == "numeric") {
    return(q * exp(-w * X))
  } else {
    return(as.vector(q * exp(-(w %*% t(X)))))
  }
}

get_poi_likelihood <- function(Xcounts, lambdas) {
  return(dpois(Xcounts, lambdas, log = TRUE))
}

multiplier_proposal <- function(i, d = 1.2) {
  u <- runif(length(i))
  l <- 2 * log(d)
  m <- exp(l * (u - 0.5))
  ii <- i * m
  hastings_ratio <- sum(log(m))
  return(list(ii, hastings_ratio))
}


.RunSampBias <- function(x,
                         rescale_counts = 1,
                         rescale_distances = 1000,
                         iterations = 1e+05,
                         burnin = 0,
                         post_samples = NULL,
                         outfile = NULL) {

  indx <- c(3:ncol(x))

  # X is the distance matrix with 1 row for each cell and 1 col for each predictor
  X <- x[, indx]/rescale_distances
  # if (length(indx) > 1) {
  #   X <- t(X)
  # }

  Xcounts <- x$record_count

  # coefficient, i.e. Poisson rate at zero distance from all
  qA <- mean(Xcounts)

  # init weigths of predictors
  wA <- abs(rnorm(length(indx), 0.01, 0.01))

  lambdas <- get_lambda_ij(qA, wA, X)

  likA <- sum(get_poi_likelihood(Xcounts, lambdas))
  priorA <- sum(dexp(1, wA, log = TRUE)) + dexp(0.01, qA, log = TRUE)

  names_b <- paste("w", names(x[, indx]), sep = "_")


  out <- data.frame()

  if (!is.null(outfile)){
    outfile <- paste("mcmc", paste(names_b[indx - 2], collapse = "_"), ".log", sep = "_")
    cat(c("it", "likA", "priorA", "q", names_b[indx - 2], "\n"), file = outfile, sep = "\t")
  }

  # print to screen
  message(paste(c("it", "likA", "priorA", "q", names_b[indx - 2]), collapse = " "))

  for (it in 1:iterations) {
    w <- wA
    q <- qA

    if (runif(1) < 0.3) {
      update <- multiplier_proposal(qA, d = 1.1)
      q <- update[[1]]
      hastings <- update[[2]]
    } else {
      update <- multiplier_proposal(wA, d = 1.05)
      w <- update[[1]]
      hastings <- update[[2]]
    }

    lambdas <- get_lambda_ij(q, w, X)
    lik <- sum(get_poi_likelihood(Xcounts, lambdas))
    prior <- sum(dexp(w, 1, log = TRUE)) + dexp(q, 0.01, log = TRUE)

    if ((lik + prior) - (likA + priorA) + hastings >= log(runif(1))) {
      likA <- lik
      priorA <- prior
      wA <- w
      qA <- q
    }

    if (it > burnin & it%%100 == 0) {
      message(paste(round(c(it, likA, priorA, qA, wA), 3), collapse = " "))

      out <- rbind(out, c(it, likA, priorA, qA, wA))

      if (!is.null(outfile)){
        cat(c(it, likA, priorA, qA, wA, "\n"), file = outfile, sep = "\t", append = TRUE)
      }
    }
  }

  if (is.null(outfile)){
    names(out) <- (c("it", "likA", "priorA", "q", names_b[indx - 2]))
    return(out)
  }
}
