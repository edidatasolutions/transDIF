# Known-truth validation for transDIF.
# 60 items; reference group n = 2000; translated (focal) group n = 50/100/200,
# 0.5 logits lower in ability. About 35% of items carry adaptation features
# that make them mostly harder in translation (directional, unbalanced DIF).
library(transDIF)

seeds <- 1:12
rows <- list()
for (nf in c(50, 100, 200)) for (s in seeds) {
  sim <- td_simulate(n_focal = nf, seed = 1000 * nf + s)
  tr <- sim$truth; c_true <- -tr$focal_mean
  cal <- td_calibrate(sim$responses, sim$group)
  dif <- suppressWarnings(td_dif(cal))
  it <- cal$items
  big <- tr$dif_item & abs(tr$dif) > 0.2
  zp <- (it$d - dif$c_purified) / it$se_d
  fz <- stats::p.adjust(2 * stats::pnorm(-abs(zp)), "BH") < 0.1
  mh <- td_mh(sim$responses, sim$group)$flag
  pw <- function(f) mean(f[big]); fd <- function(f) if (any(f)) mean(!tr$dif_item[f]) else 0
  e_eb <- dif$items$dif_mean - tr$dif; e_raw <- it$d - dif$c_purified - tr$dif
  rows[[length(rows) + 1]] <- data.frame(n_focal = nf, weak = dif$weakly_identified,
    err_c_mode = dif$link[["c"]] - c_true, err_c_mean = dif$c_mean - c_true,
    err_c_purified = dif$c_purified - c_true,
    c_covered = abs(dif$link[["c"]] - c_true) < 1.645 * dif$link[["c_se"]],
    power_eb = pw(dif$items$flag), fdp_eb = fd(dif$items$flag),
    power_purified_z = pw(fz), fdp_purified_z = fd(fz),
    power_mh = pw(mh), fdp_mh = fd(mh),
    rmse_dif_eb = sqrt(mean(e_eb^2)), rmse_dif_raw = sqrt(mean(e_raw^2)),
    rmse_null_eb = sqrt(mean(e_eb[!tr$dif_item]^2)), rmse_null_raw = sqrt(mean(e_raw[!tr$dif_item]^2)))
}
r <- do.call(rbind, rows)
cat("Linking shift c (true 0.5): bias and RMSE\n")
lk <- r[c("n_focal", "err_c_mode", "err_c_mean", "err_c_purified")]
b <- stats::aggregate(. ~ n_focal, lk, mean); m <- stats::aggregate(. ~ n_focal, lk, function(v) sqrt(mean(v^2)))
names(b)[-1] <- paste0("bias_", sub("err_c_", "", names(b)[-1]))
names(m)[-1] <- paste0("rmse_", sub("err_c_", "", names(m)[-1]))
print(merge(b, m), digits = 3, row.names = FALSE)
cat("\nMode linking SE: 90% interval coverage", round(mean(r$c_covered), 3), "\n")
cat("\nAmbiguous-linking warnings, share by n_focal:\n")
print(stats::aggregate(weak ~ n_focal, r, mean), digits = 3, row.names = FALSE)
cat("Linking RMSE excluding weakly identified fits:\n")
ok <- r[!r$weak, c("n_focal", "err_c_mode", "err_c_mean", "err_c_purified")]
print(stats::aggregate(. ~ n_focal, ok, function(v) sqrt(mean(v^2))), digits = 3, row.names = FALSE)
cat("\nDIF detection (DIF > 0.2 logits), target FDR 10%:\n")
print(stats::aggregate(cbind(power_eb, fdp_eb, power_purified_z, fdp_purified_z, power_mh, fdp_mh) ~ n_focal,
                       r, mean), digits = 3, row.names = FALSE)
cat("EB detection excluding weakly identified fits:\n")
print(stats::aggregate(cbind(power_eb, fdp_eb) ~ n_focal, r[!r$weak, ], mean), digits = 3, row.names = FALSE)
cat("\nDIF effect estimation RMSE (all items / DIF-free items):\n")
print(stats::aggregate(cbind(rmse_dif_eb, rmse_dif_raw, rmse_null_eb, rmse_null_raw) ~ n_focal, r, mean),
      digits = 3, row.names = FALSE)

# Aggregate impact and feature explanation at n_focal = 150.
ns <- asNamespace("transDIF"); nodes <- stats::qnorm(stats::ppoints(61))
imp_rows <- list(); fe_rows <- list()
true_eff <- c(idiom = 0.6, cultural = 0.5, units = -0.4, vocabulary = 0.35)
for (s in seeds) {
  sim <- td_simulate(n_focal = 150, seed = 5000 + s); tr <- sim$truth
  dif <- suppressWarnings(td_dif(td_calibrate(sim$responses, sim$group)))
  imp <- td_impact(dif, cut = 36, n_draws = 200, seed = s)
  ch <- imp[imp$quantity == "pass_rate_change", ]
  truth <- ns$pass_rate(tr$b_ref + tr$dif, 36, tr$focal_mean, tr$focal_sd, nodes) -
           ns$pass_rate(tr$b_ref, 36, tr$focal_mean, tr$focal_sd, nodes)
  imp_rows[[s]] <- data.frame(true_change = truth, estimate = ch$estimate,
                              covered = truth >= ch$lower & truth <= ch$upper)
  fe <- td_features(dif, sim$features)
  fe <- fe[fe$term %in% names(true_eff), ]
  fe_rows[[s]] <- data.frame(term = fe$term, estimate = fe$estimate,
                             covered = abs(fe$estimate - true_eff[fe$term]) < 1.96 * fe$se)
}
ir <- do.call(rbind, imp_rows)
cat(sprintf("\nPass-rate change (n_focal = 150): true mean %+.3f, estimated mean %+.3f, 90%% interval coverage %.2f\n",
            mean(ir$true_change), mean(ir$estimate), mean(ir$covered)))
fr <- do.call(rbind, fe_rows)
fa <- stats::aggregate(cbind(estimate, covered) ~ term, fr, mean)
fa$true <- true_eff[fa$term]
cat("\nFeature effects (n_focal = 150): mean estimate vs truth, 95% CI coverage\n")
print(fa, digits = 3, row.names = FALSE)
