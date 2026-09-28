# Evaluate td_dif(link = "mode") against link = "mixture" on the cached calibrations.
suppressMessages(library(transDIF))
cache <- readRDS("C:/Users/User/Documents/transDIF/dev/bench_cache.rds")
rows <- list()
for (x in cache) {
  big <- x$dif_item & abs(x$dif) > 0.2
  for (m in c("mode", "mixture")) {
    dif <- suppressWarnings(td_dif(x$cal, link = m))
    fl <- dif$items$flag
    err <- dif$link[["c"]] - x$c_true
    rows[[length(rows) + 1]] <- data.frame(
      scenario = x$scenario, n_focal = x$n_focal, method = m, err = err,
      covered = abs(err) < 1.645 * dif$link[["c_se"]], c_se = dif$link[["c_se"]],
      weak = dif$weakly_identified,
      power = mean(fl[big]), fdp = if (any(fl)) mean(!x$dif_item[fl]) else 0,
      rmse_dif = sqrt(mean((dif$items$dif_mean - x$dif)^2)))
  }
}
r <- do.call(rbind, rows)
agg <- function(f) aggregate(cbind(err, covered, weak, power, fdp, rmse_dif) ~ method + n_focal + scenario,
                             r, f)
s <- aggregate(cbind(rmse_c = err) ~ method + n_focal + scenario, r, function(v) sqrt(mean(v^2)))
m <- aggregate(cbind(bias = err, cover90 = covered, weak, power, fdp, rmse_dif) ~ method + n_focal + scenario,
               r, mean)
out <- merge(s, m)
print(out[order(out$scenario, out$n_focal, out$method), ], digits = 3, row.names = FALSE)
cat("\nOverall by method:\n")
print(aggregate(cbind(cover90 = covered, weak, power, fdp, rmse_dif) ~ method, r, mean), digits = 3)
print(aggregate(cbind(rmse_c = err) ~ method, r, function(v) sqrt(mean(v^2))), digits = 3)
cat("\nMode: |error| when the ambiguity warning fires vs not:\n")
mm <- r[r$method == "mode", ]
print(aggregate(abs(err) ~ weak, mm, mean), digits = 3)
print(table(weak = mm$weak))
