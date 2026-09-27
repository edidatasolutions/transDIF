for (f in list.files("C:/Users/User/Documents/transDIF/R", full.names = TRUE)) source(f)
res <- list()
for (nf in c(50, 100, 200)) for (s in 1:8) {
  sim <- td_simulate(n_focal = nf, seed = 100 * nf + s)
  cal <- td_calibrate(sim$responses, sim$group)
  dif <- td_dif(cal)
  tr <- sim$truth; big <- tr$dif_item & abs(tr$dif) > 0.2
  it <- cal$items
  # purified-z detection with BH
  zp <- (it$d - dif$c_purified) / it$se_d
  fz <- p.adjust(2 * pnorm(-abs(zp)), "BH") < 0.1
  mh <- td_mh(sim$responses, sim$group)
  pw <- function(fl) mean(fl[big]); fd <- function(fl) if (any(fl)) mean(!tr$dif_item[fl]) else 0
  res[[length(res) + 1]] <- data.frame(n_focal = nf,
    c_eb = dif$link[["c"]] - 0.5, c_mean = dif$c_mean - 0.5, c_pur = dif$c_purified - 0.5,
    c_anc5 = with(dif$items, weighted.mean(d[p_dif < 0.5], 1 / se_d[p_dif < 0.5]^2)) - 0.5,
    c_post = with(dif$items, weighted.mean(d, (1 - p_dif) / se_d^2)) - 0.5,
    pow_eb = pw(dif$items$flag), fdp_eb = fd(dif$items$flag),
    pow_pz = pw(fz), fdp_pz = fd(fz), pow_mh = pw(mh$flag), fdp_mh = fd(mh$flag),
    rmse_eb = sqrt(mean((dif$items$dif_mean - tr$dif)^2)),
    rmse_raw = sqrt(mean((it$d - dif$c_purified - tr$dif)^2)))
}
r <- do.call(rbind, res)
rm <- function(v) sqrt(mean(v^2))
print(aggregate(cbind(c_eb, c_anc5, c_post, c_mean, c_pur) ~ n_focal, r, rm), digits = 3)
print(aggregate(cbind(c_eb, c_anc5, c_post, c_mean, c_pur) ~ n_focal, r, mean), digits = 3)
print(aggregate(cbind(pow_eb, fdp_eb, pow_pz, fdp_pz, pow_mh, fdp_mh, rmse_eb, rmse_raw) ~ n_focal, r, mean), digits = 3)
