for (f in list.files("C:/Users/User/Documents/transDIF/R", full.names = TRUE)) source(f)
sim <- td_simulate(n_focal = 150, seed = 2)
tr <- sim$truth
cat("true DIF items:", sum(tr$dif_item), " mean true DIF:", mean(tr$dif), "\n")
t0 <- Sys.time(); cal <- td_calibrate(sim$responses, sim$group); cat("calibrate:", format(Sys.time() - t0), "\n")
it <- cal$items
cat("ref b recovery r:", cor(it$b_ref, tr$b_ref), " focal sigma:", cal$sigma_focal, "\n")
# SE honesty: z of d around truth (c + dif) where c = -focal_mean
zd <- (it$d - (0.5 + tr$dif)) / it$se_d
cat("d z mean/sd:", mean(zd), sd(zd), "\n")
dif <- td_dif(cal); print(dif)
cat("c true 0.5 | robust", dif$link[["c"]], " mean", dif$c_mean, " purified", dif$c_purified, "\n")
fl <- dif$items$flag
cat("EB: power", mean(fl[tr$dif_item & abs(tr$dif) > 0.2]), " FDP", if (any(fl)) mean(!tr$dif_item[fl]) else 0, "\n")
mh <- td_mh(sim$responses, sim$group)
cat("MH: power", mean(mh$flag[tr$dif_item & abs(tr$dif) > 0.2]), " FDP", if (any(mh$flag)) mean(!tr$dif_item[mh$flag]) else 0, "\n")
cat("DIF estimate RMSE: EB", sqrt(mean((dif$items$dif_mean - tr$dif)^2)),
    " raw (d - c_mean)", sqrt(mean((it$d - dif$c_mean - tr$dif)^2)), "\n")
imp <- td_impact(dif, cut = 36, seed = 1); print(imp)
tru_fair <- pass_rate(tr$b_ref, 36, -0.5, 1, qnorm(ppoints(61)))
tru_tr <- pass_rate(tr$b_ref + tr$dif, 36, -0.5, 1, qnorm(ppoints(61)))
cat("true pass change:", tru_tr - tru_fair, "\n")
print(td_features(dif, sim$features))
cat(substr(td_report(dif, imp, td_features(dif, sim$features), c("English", "French")), 1, 1500), "\n")
