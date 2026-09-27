library(transDIF)
ns <- asNamespace("transDIF"); nodes <- qnorm(ppoints(61))
rows <- list()
for (s in 1:12) {
  sim <- td_simulate(n_focal = 200, seed = 200000 + s); tr <- sim$truth
  cal <- td_calibrate(sim$responses, sim$group)
  dif <- td_dif(cal)
  l <- dif$link
  rows[[s]] <- data.frame(seed = s, err = l[["c"]] - 0.5, c_se = l[["c_se"]], pi0 = l[["pi0"]],
                          true_pi0 = mean(!tr$dif_item), m1 = l[["m1"]], tau1 = l[["tau1"]],
                          err_pur = dif$c_purified - 0.5, n_flag = sum(dif$items$flag),
                          fdp = if (any(dif$items$flag)) mean(!tr$dif_item[dif$items$flag]) else 0)
}
print(do.call(rbind, rows), digits = 3)
# Impact coverage after propagating linking uncertainty (n_focal = 150).
cov <- sapply(1:12, function(s) {
  sim <- td_simulate(n_focal = 150, seed = 5000 + s); tr <- sim$truth
  dif <- td_dif(td_calibrate(sim$responses, sim$group))
  ch <- td_impact(dif, cut = 36, n_draws = 200, seed = s)
  ch <- ch[ch$quantity == "pass_rate_change", ]
  truth <- ns$pass_rate(tr$b_ref + tr$dif, 36, tr$focal_mean, 1, nodes) -
           ns$pass_rate(tr$b_ref, 36, tr$focal_mean, 1, nodes)
  c(truth >= ch$lower & truth <= ch$upper, ch$upper - ch$lower)
})
cat("impact coverage:", mean(cov[1, ]), " mean width:", mean(cov[2, ]), "\n")
