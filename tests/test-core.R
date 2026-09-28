library(transDIF)
ns <- asNamespace("transDIF")

# 1. Score distribution and pass rate -----------------------------------------------
D <- ns$lw_dist(c(-1, 0, 2), c(-0.5, 0, 0.5, 1))
stopifnot(all(abs(rowSums(D) - 1) < 1e-12), ncol(D) == 5,
          abs(sum(D[2, ] * 0:4) - sum(plogis(0 - c(-0.5, 0, 0.5, 1)))) < 1e-12)

# 2. Calibration: recovery and honest relative SEs ------------------------------------
sim <- td_simulate(n_ref = 1500, n_focal = 200, n_items = 40, seed = 9)
tr <- sim$truth
cal <- td_calibrate(sim$responses, sim$group)
it <- cal$items
stopifnot(cor(it$b_ref, tr$b_ref) > 0.99,
          abs(cal$sigma_focal - tr$focal_sd) < 0.2)
z <- (it$d - (-tr$focal_mean + tr$dif)) / it$se_d
stopifnot(abs(sd(z) - 1) < 0.25)

# 3. Robust linking beats mean linking under directional DIF; flags are real ----------
dif <- td_dif(cal)
stopifnot(abs(dif$link[["c"]] + tr$focal_mean) < abs(dif$c_mean + tr$focal_mean) + 0.02,
          dif$link[["pi0"]] > 0.5)
fl <- dif$items$flag
if (any(fl)) stopifnot(mean(!tr$dif_item[fl]) <= 0.25)
big <- tr$dif_item & abs(tr$dif) > 0.4
stopifnot(mean(fl[big]) >= 0.5)
# Shrinkage trades a little accuracy on real DIF items for much better
# accuracy on DIF-free ones; overall it should not be meaningfully worse.
e_eb <- dif$items$dif_mean - tr$dif; e_raw <- it$d - dif$link[["c"]] - tr$dif
rmse <- function(e) sqrt(mean(e^2))
stopifnot(rmse(e_eb[!tr$dif_item]) < 0.8 * rmse(e_raw[!tr$dif_item]),
          rmse(e_eb) < 1.1 * rmse(e_raw))

# 4. Aggregate impact brackets the truth ------------------------------------------------
cut <- 24
imp <- td_impact(dif, cut = cut, n_draws = 100, seed = 1)
nodes <- qnorm(ppoints(61))
true_change <- ns$pass_rate(tr$b_ref + tr$dif, cut, tr$focal_mean, tr$focal_sd, nodes) -
               ns$pass_rate(tr$b_ref, cut, tr$focal_mean, tr$focal_sd, nodes)
ch <- imp[imp$quantity == "pass_rate_change", ]
stopifnot(ch$estimate < 0, abs(ch$estimate - true_change) < 0.03)

# 5. Features: signs of strong effects recovered ------------------------------------------
fe <- td_features(dif, sim$features)
est <- setNames(fe$estimate, fe$term)
stopifnot(est[["idiom"]] > 0.2, est[["cultural"]] > 0.1, est[["units"]] < 0)

# 6. MH baseline and report ---------------------------------------------------------------
mh <- td_mh(sim$responses, sim$group)
stopifnot(nrow(mh) == 40, all(mh$p_value >= 0 & mh$p_value <= 1))
rep <- td_report(dif, imp, fe, c("English", "French"))
stopifnot(grepl("French", rep), grepl("Aggregate impact", rep), grepl("translators", rep))
# Weighted-mode linking: finds the majority cluster, not the mean.
lm1 <- ns$link_mode(c(rep(0.5, 12), rep(1.3, 5)) + rnorm(17, 0, 0.02), rep(0.15, 17))
stopifnot(abs(lm1$c - 0.5) < 0.05, lm1$se > 0, lm1$alt_ratio < 0.8)
# Two equally dense clusters: the linking is flagged as ambiguous.
amb <- cal
amb$items$d <- c(rep(0.2, 20), rep(1.2, 20)) + rnorm(40, 0, 0.03)
amb$items$se_d <- 0.15
w <- NULL
dif_amb <- withCallingHandlers(td_dif(amb), warning = function(x) {
  w <<- conditionMessage(x); invokeRestart("muffleWarning") })
stopifnot(isTRUE(dif_amb$weakly_identified), grepl("ambiguous", w),
          grepl("ambiguous", td_report(dif_amb)))
# The previous joint-mixture linking remains available.
stopifnot(td_dif(cal, link = "mixture")$method == "mixture")

# Linking sensitivity: clear cluster -> robust; two equal clusters -> sensitive.
clear <- cal
set.seed(3)
clear$items$d <- c(rep(0.5, 34), 0.5 + c(0.6, 0.7, 0.8, -0.6, 0.9, 0.7)) + rnorm(40, 0, 0.02)
clear$items$se_d <- 0.05
s_clear <- td_sensitivity(suppressWarnings(td_dif(clear)), B = 100, seed = 1)
stopifnot(s_clear$verdict == "robust", s_clear$range < 0.15,
          all(c("mode", "purified", "all_items") %in% s_clear$linkings$assumption))
s_amb <- td_sensitivity(suppressWarnings(td_dif(amb)), B = 100, seed = 1)
stopifnot(s_amb$verdict == "sensitive", s_amb$range > 0.15,
          grepl("Sensitivity to the linking assumption", td_report(dif_amb, sensitivity = s_amb)))
# With a cut, each linking gets a pass-rate impact.
s_cut <- td_sensitivity(dif, cut = 24, B = 50, n_draws = 30, seed = 2)
stopifnot(all(c("pass_rate_change", "change_lower", "change_upper") %in% names(s_cut$linkings)))

# A feature on no item is dropped with a warning instead of failing.
feat0 <- sim$features; feat0$units <- 0
fe0 <- withCallingHandlers(td_features(dif, feat0),
                           warning = function(w) invokeRestart("muffleWarning"))
stopifnot(!"units" %in% fe0$term, "idiom" %in% fe0$term)
cat("All transDIF tests passed.\n")
