# Find a seed for the documentation examples where every item feature occurs
# at least twice among 20 items, so td_features() needs to drop nothing.
library(transDIF)
for (s in 1:60) {
  sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = s)
  v <- colSums(sim$features[-1])
  if (all(v >= 2)) { cat("seed", s, ":", v, "\n"); break }
}
