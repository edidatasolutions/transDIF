#' Sensitivity of the comparability conclusions to the linking assumption
#'
#' Linking two language groups requires an assumption about which items are
#' free of DIF, and when DIF is pervasive on a short test the data may not
#' settle it. This function makes that dependence visible:
#' \describe{
#'   \item{Linking assumptions}{The ability difference under the weighted
#'     mode (DIF-free items form the densest cluster), iterative purification,
#'     and all items as anchors (DIF cancels out), with the DIF model refitted
#'     under each and, if `cut` is given, the pass-rate impact under each.}
#'   \item{Stability of the mode}{A parametric bootstrap redraws each item's
#'     between-language difference from its sampling distribution and
#'     re-estimates the mode. When DIF-free items form a clear cluster the
#'     bootstrap modes stay close to the estimate; when they do not, the mode
#'     jumps between clusters, which is exactly the failure a single estimate
#'     hides.}
#'   \item{Linking-sensitive items}{Items whose DIF flag changes across the
#'     linking assumptions. These are the items to prioritize for review by
#'     content and translation experts.}
#' }
#' The overall verdict is `"robust"` when the linkings agree within
#' `tolerance` logits and the bootstrap keeps at least `stable_share` of the
#' modes within `tolerance` of the estimate; otherwise `"sensitive"`.
#'
#' **What the verdict means.** It is a statement about *dependence on an
#' untestable assumption*, not an estimate of which linking is correct. In the
#' package's known-truth simulations, "sensitive" verdicts were concentrated
#' in the hardest designs (short tests, small translated-language groups,
#' pervasive DIF), where linking errors are larger for every method; within a
#' given design, the verdict did not separate more accurate estimates from
#' less accurate ones. Disagreement between linkings arose mostly because mean
#' and purified linking are biased under heavy directional DIF. Use the
#' verdict to decide when to report results under several assumptions and to
#' send the linking-sensitive items to content and translation experts; only
#' that review can settle which items should anchor the scale. Items near the
#' flagging boundary can be linking-sensitive even when the verdict is
#' robust.
#'
#' @param dif A `td_dif` object (from [td_dif()]).
#' @param cut Optional raw-score passing standard for pass-rate impact.
#' @param tolerance Difference in the linking shift (logits) considered
#'   substantively negligible.
#' @param stable_share Minimum share of bootstrap modes within `tolerance`
#'   of the estimate for the mode to count as stable.
#' @param B Bootstrap replicates.
#' @param n_draws Posterior draws for each pass-rate impact.
#' @param seed Optional seed.
#' @return A `td_sensitivity` object: `$linkings` (one row per assumption:
#'   `assumption`, `shift`, `focal_mean`, `se`, `n_flagged`, and pass-rate
#'   impact columns when `cut` is given), `$bootstrap` (`sd`, `lower`,
#'   `upper` (90% interval), `share_within`), `$items` (flags under each
#'   linking and a `linking_sensitive` indicator), `$range` (largest
#'   difference between linkings) and `$verdict`.
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' sens <- td_sensitivity(dif, cut = 12, B = 50, n_draws = 20, seed = 1)
#' sens
#' @export
td_sensitivity <- function(dif, cut = NULL, tolerance = 0.15, stable_share = 0.8,
                           B = 200, n_draws = 100, seed = NULL) {
  if (!inherits(dif, "td_dif")) stop("`dif` must come from td_dif().")
  if (!is.null(seed)) set.seed(seed)
  cal <- dif$calibration
  it <- cal$items
  d <- it$d; se <- it$se_d
  tau0 <- if (!is.null(dif$tau0)) dif$tau0 else dif$link[["tau0"]]
  w <- 1 / se^2
  kept <- if (!is.null(dif$purified_items)) it$item %in% dif$purified_items else rep(TRUE, nrow(it))
  shifts <- list(
    mode = c(dif$link[["c"]], dif$link[["c_se"]]),
    purified = c(dif$c_purified, sqrt(1 / sum(w[kept]) + cal$loc_var)),
    all_items = c(dif$c_mean, sqrt(1 / sum(w) + cal$loc_var)))

  fits <- lapply(names(shifts), function(a) {
    if (a == "mode") return(dif)
    suppressWarnings(td_dif(cal, fdr = dif$fdr, tau0 = tau0,
                            c_fixed = shifts[[a]][1], c_se_fixed = shifts[[a]][2]))
  })
  names(fits) <- names(shifts)
  lk <- data.frame(assumption = names(shifts),
                   shift = vapply(shifts, `[`, 0, 1),
                   se = vapply(shifts, `[`, 0, 2),
                   n_flagged = vapply(fits, function(f) sum(f$items$flag), 0),
                   row.names = NULL, stringsAsFactors = FALSE)
  lk$focal_mean <- -lk$shift
  if (!is.null(cut)) {
    imp <- lapply(fits, function(f) {
      x <- td_impact(f, cut = cut, n_draws = n_draws)
      x[x$quantity == "pass_rate_change", c("estimate", "lower", "upper")]
    })
    lk$pass_rate_change <- vapply(imp, function(x) x$estimate, 0)
    lk$change_lower <- vapply(imp, function(x) x$lower, 0)
    lk$change_upper <- vapply(imp, function(x) x$upper, 0)
  }
  lk <- lk[c("assumption", "shift", "focal_mean", "se", "n_flagged",
             intersect(c("pass_rate_change", "change_lower", "change_upper"), names(lk)))]

  # Parametric bootstrap of the weighted mode.
  s <- sqrt(se^2 + tau0^2)
  boot <- vapply(seq_len(B), function(b) link_mode(stats::rnorm(length(d), d, se), s)$c, 0)
  share <- mean(abs(boot - dif$link[["c"]]) <= tolerance)
  bs <- c(sd = stats::sd(boot), lower = unname(stats::quantile(boot, 0.05)),
          upper = unname(stats::quantile(boot, 0.95)), share_within = share)

  flags <- vapply(fits, function(f) f$items$flag, logical(nrow(it)))
  items <- data.frame(item = it$item, d = d,
                      flag_mode = flags[, "mode"], flag_purified = flags[, "purified"],
                      flag_all_items = flags[, "all_items"], stringsAsFactors = FALSE)
  items$linking_sensitive <- apply(flags, 1, function(v) length(unique(v)) > 1)
  rng <- diff(range(lk$shift))
  verdict <- if (rng <= tolerance && share >= stable_share) "robust" else "sensitive"
  structure(list(linkings = lk, bootstrap = bs, items = items, range = rng, verdict = verdict,
                 tolerance = tolerance, stable_share = stable_share, cut = cut, B = B),
            class = "td_sensitivity")
}

#' @export
print.td_sensitivity <- function(x, ...) {
  cat(sprintf("<td_sensitivity> verdict: %s (tolerance %.2f logits)\n", toupper(x$verdict), x$tolerance))
  cat(sprintf("Linkings differ by up to %.3f logits; %.0f%% of %d bootstrap modes fall within %.2f of the estimate (90%% interval %.3f to %.3f)\n\n",
              x$range, 100 * x$bootstrap[["share_within"]], x$B, x$tolerance,
              x$bootstrap[["lower"]], x$bootstrap[["upper"]]))
  print(x$linkings, digits = 3, row.names = FALSE)
  s <- x$items[x$items$linking_sensitive, ]
  cat(sprintf("\n%d linking-sensitive item(s)%s\n", nrow(s), if (nrow(s)) ":" else ""))
  if (nrow(s)) print(s, digits = 3, row.names = FALSE)
  invisible(x)
}
