for (f in list.files("C:/Users/User/Documents/transDIF/R", full.names = TRUE)) source(f)
# Prototype: spike + positive slab + negative slab.
nll2 <- function(q, d, se) {
  c0 <- q[1]; t0 <- exp(q[2])
  mp <- exp(q[3]); tp <- exp(q[4]); mn <- -exp(q[5]); tn <- exp(q[6])
  w <- exp(c(0, q[7], q[8])); w <- w / sum(w)       # w[1] = spike
  p0 <- 0.5 + 0.5 * w[1]; rest <- (1 - p0) * w[2:3] / sum(w[2:3])
  f <- p0 * stats::dnorm(d, c0, sqrt(se^2 + t0^2)) +
       rest[1] * stats::dnorm(d, c0 + mp, sqrt(se^2 + tp^2)) +
       rest[2] * stats::dnorm(d, c0 + mn, sqrt(se^2 + tn^2))
  -sum(log(f + 1e-300))
}
fit2 <- function(d, se) {
  best <- NULL
  for (st in list(c(median(d), log(.05), log(.5), log(.3), log(.5), log(.3), 0, 0),
                  c(median(d), log(.02), log(.3), log(.2), log(.3), log(.2), 1, -1))) {
    o <- optim(st, nll2, d = d, se = se, method = "BFGS", control = list(maxit = 2000))
    if (is.null(best) || o$value < best$value) best <- o
  }
  q <- best$par; w <- exp(c(0, q[7], q[8])); w <- w / sum(w)
  c(c = q[1], pi0 = 0.5 + 0.5 * w[1], nll = best$value)
}
res <- list()
for (nf in c(50, 100, 200)) for (s in 1:8) {
  sim <- td_simulate(n_focal = nf, seed = 100 * nf + s)
  cal <- td_calibrate(sim$responses, sim$group)
  dif <- td_dif(cal)
  f2 <- fit2(cal$items$d, cal$items$se_d)
  tr <- sim$truth
  fl <- dif$items$flag
  res[[length(res) + 1]] <- data.frame(n_focal = nf, seed = s,
    true_pi0 = mean(!tr$dif_item),
    c1_err = dif$link[["c"]] - 0.5, c2_err = f2[["c"]] - 0.5, cmean_err = dif$c_mean - 0.5,
    cpur_err = dif$c_purified - 0.5,
    pi0_1 = dif$link[["pi0"]], pi0_2 = f2[["pi0"]],
    nll1 = mix_nll(c(dif$link[["c"]], dif$link[["m1"]], log(dif$link[["tau0"]]), log(dif$link[["tau1"]]),
                     qlogis(dif$link[["pi0"]])), cal$items$d, cal$items$se_d), nll2 = f2[["nll"]],
    power = mean(fl[tr$dif_item & abs(tr$dif) > 0.2]),
    fdp = if (any(fl)) mean(!tr$dif_item[fl]) else 0,
    anchors = sum(dif$items$anchor),
    z_sd = sd((cal$items$d - (0.5 + tr$dif)) / cal$items$se_d),
    c_z = (dif$link[["c"]] - 0.5) / dif$link[["c_se"]])
}
r <- do.call(rbind, res)
print(aggregate(. ~ n_focal, r[setdiff(names(r), "seed")], function(v) round(mean(v), 3)))
cat("RMSE of c by n_focal:\n")
print(aggregate(cbind(c1_err, c2_err, cmean_err, cpur_err) ~ n_focal, r, function(v) round(sqrt(mean(v^2)), 3)))
cat("sd of c_z:", sd(r$c_z), "\n")
