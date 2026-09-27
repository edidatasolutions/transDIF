# Compare linking estimators on cached calibrations.
suppressMessages(library(transDIF))
cache <- readRDS("C:/Users/User/Documents/transDIF/dev/bench_cache.rds")
tau0 <- 0.05

# Weighted mode: maximize sum_i phi((c - d_i)/s_i)/s_i (a Welsch-type,
# strongly redescending estimator); global search on a fine grid.
est_mode <- function(d, se) {
  s <- sqrt(se^2 + tau0^2)
  g <- seq(min(d), max(d), length.out = 2001)
  f <- vapply(g, function(c) sum(dnorm((c - d) / s) / s), 0)
  g[which.max(f)]
}
# Tukey biweight M-estimator by IRLS from a given start.
biweight <- function(d, se, start, k = 4.685, iter = 100) {
  s <- sqrt(se^2 + tau0^2); c0 <- start
  for (i in 1:iter) {
    r <- (d - c0) / s
    w <- ifelse(abs(r) < k, (1 - (r / k)^2)^2, 0) / s^2
    c1 <- sum(w * d) / sum(w)
    if (abs(c1 - c0) < 1e-10) break
    c0 <- c1
  }
  c0
}
# Least trimmed squares on standardized residuals (50% + 1 kept).
est_lts <- function(d, se) {
  s <- sqrt(se^2 + tau0^2); h <- floor(length(d) / 2) + 1
  g <- seq(min(d), max(d), length.out = 2001)
  obj <- vapply(g, function(c) sum(sort(((d - c) / s)^2)[1:h]), 0)
  c0 <- g[which.min(obj)]
  keep <- order(((d - c0) / s)^2)[1:h]
  sum(d[keep] / s[keep]^2) / sum(1 / s[keep]^2)
}

rows <- list()
for (x in cache) {
  it <- x$cal$items; d <- it$d; se <- it$se_d
  dif <- suppressWarnings(td_dif(x$cal))
  m <- est_mode(d, se)
  rows[[length(rows) + 1]] <- data.frame(
    scenario = x$scenario, n_focal = x$n_focal,
    mixture = dif$link[["c"]], purified = dif$c_purified, mean = dif$c_mean,
    median = median(d), mode = m,
    biw_med = biweight(d, se, median(d)), biw_mode = biweight(d, se, m),
    biw_mode_k3 = biweight(d, se, m, k = 3), lts = est_lts(d, se)) |>
    transform(truth = x$c_true)
}
r <- do.call(rbind, rows)
meths <- c("mixture", "purified", "mean", "median", "mode", "biw_med", "biw_mode", "biw_mode_k3", "lts")
err <- r[meths] - r$truth
cat("RMSE by scenario x n_focal:\n")
print(aggregate(err, r[c("scenario", "n_focal")], function(v) round(sqrt(mean(v^2)), 3)))
cat("\nBias:\n")
print(aggregate(err, r[c("scenario", "n_focal")], function(v) round(mean(v), 3)))
cat("\nOverall RMSE:\n")
print(round(sapply(err, function(v) sqrt(mean(v^2))), 3))
