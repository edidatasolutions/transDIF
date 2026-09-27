# Cache calibrations for the linking benchmark (slow part), so estimators
# can be compared quickly on identical data.
library(transDIF)
scen <- list(
  base = list(),
  heavy = list(feature_prev = c(idiom = 0.15, cultural = 0.15, units = 0.12, vocabulary = 0.17)),
  balanced = list(feature_effects = c(idiom = 0.6, cultural = -0.5, units = -0.4, vocabulary = 0.35))
)
out <- list()
for (sc in names(scen)) for (nf in c(50, 100, 200)) for (s in 1:20) {
  sim <- do.call(td_simulate, c(list(n_focal = nf, seed = 70000 + 1000 * match(sc, names(scen)) + 10 * nf + s),
                                scen[[sc]]))
  cal <- td_calibrate(sim$responses, sim$group)
  out[[length(out) + 1]] <- list(scenario = sc, n_focal = nf, seed = s, cal = cal,
                                 dif = sim$truth$dif, dif_item = sim$truth$dif_item,
                                 c_true = -sim$truth$focal_mean)
}
saveRDS(out, "C:/Users/User/Documents/transDIF/dev/bench_cache.rds")
cat("cached", length(out), "\n")
