# Negative marginal log-likelihood of the spike-and-slab model.
# par = (c, m1, log tau0, log tau1, logit pi0); pi0 is the DIF-free share.
mix_nll <- function(par, d, se) {
  c0 <- par[1]; m1 <- par[2]; t0 <- exp(par[3]); t1 <- exp(par[4])
  p0 <- stats::plogis(par[5])
  f0 <- stats::dnorm(d, c0, sqrt(se^2 + t0^2))
  f1 <- stats::dnorm(d, c0 + m1, sqrt(se^2 + t1^2))
  -sum(log(p0 * f0 + (1 - p0) * f1 + 1e-300))
}

#' Robust linking, anchor selection and small-sample DIF in one model
#'
#' The between-language difference of item `i` is modeled as
#' `d_i ~ N(c + delta_i, se_i^2)`, with DIF effects from a spike-and-slab
#' mixture:
#' \itemize{
#'   \item DIF-free (share `pi0`): `delta_i ~ N(0, tau0^2)`, where `tau0` is small;
#'   \item DIF (share `1 - pi0`): `delta_i ~ N(m1, tau1^2)`, where `m1` allows the
#'     directional DIF typical of translation.
#' }
#' The common shift `c` is the ability difference that linking must recover.
#' It is identified by the spike, i.e. by the assumption that a majority of
#' items are DIF-free (`pi0 > 0.5`), not by assuming DIF cancels out as mean
#' linking does. The spike's SD `tau0` is fixed at a negligible-DIF scale
#' rather than estimated. Left free, it can widen to swallow moderate DIF,
#' which destabilizes the linking shift. Remaining parameters are estimated by
#' marginal ML with several starts. Each item gets a posterior DIF
#' probability, a shrunken DIF estimate, and a local false discovery rate.
#'
#' @param calibration An `td_calibration`.
#' @param fdr Target Bayesian false discovery rate for flagging.
#' @param tau0 SD of DIF among "DIF-free" items: the scale of DIF considered
#'   negligible (logits).
#' @param anchor_max Items with posterior DIF probability below this are
#'   reported as anchors.
#' @return An `td_dif` object: `$items` (`item`, `d`, `se_d`, `p_dif`, `lfdr`,
#'   `dif_mean`, `dif_sd` (posterior mean/SD of DIF), `flag`, `anchor`) and
#'   `$link` (`c`, `c_se`, `pi0`, `m1`, `tau0`, `tau1`), baseline linking
#'   constants `c_mean` (all items as anchors) and `c_purified`, and
#'   `weakly_identified` (TRUE, with a warning, when `pi0` sits at its 0.5
#'   bound; in simulation such fits gave the largest linking errors and
#'   false-discovery rates, so rely on `c_purified` and expert review then).
#' @examples
#' sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' dif
#' # true linking shift is -focal_mean = 0.5
#' c(estimate = dif$link[["c"]], mean_linking = dif$c_mean)
#' @export
td_dif <- function(calibration, fdr = 0.1, tau0 = 0.05, anchor_max = 0.2) {
  it <- calibration$items
  d <- it$d; se <- it$se_d
  # Free parameters q = (c, m1, log(tau1 - tau0), logit of (2 pi0 - 1)):
  # pi0 > 0.5 and tau1 > tau0 hold by construction.
  wrap <- function(q) c(q[1], q[2], log(tau0), log(tau0 + exp(q[3])),
                        stats::qlogis(0.5 + 0.5 * stats::plogis(q[4])))
  # The likelihood can be multimodal in c when SEs are large (small focal
  # groups), so start from a grid of c values across the bulk of d.
  cs <- stats::quantile(d, seq(0.2, 0.8, by = 0.1), names = FALSE)
  starts <- c(lapply(cs, function(c0) c(c0, 0.5, log(0.4), 0.5)),
              lapply(cs, function(c0) c(c0, -0.5, log(0.4), 0.5)))
  best <- NULL
  for (s in starts) {
    o <- tryCatch(stats::optim(s, function(q) mix_nll(wrap(q), d, se),
                               method = "BFGS", hessian = TRUE, control = list(maxit = 1000)),
                  error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o
  }
  par <- wrap(best$par)
  c0 <- par[1]; m1 <- par[2]; t0 <- exp(par[3]); t1 <- exp(par[4]); p0 <- stats::plogis(par[5])
  # Linking SE: mixture-estimation uncertainty plus the scales' location variance.
  c_se <- tryCatch(sqrt(solve(best$hessian)[1, 1] + calibration$loc_var),
                   error = function(e) NA_real_)

  v0 <- se^2 + t0^2; v1 <- se^2 + t1^2
  f0 <- p0 * stats::dnorm(d, c0, sqrt(v0)); f1 <- (1 - p0) * stats::dnorm(d, c0 + m1, sqrt(v1))
  p_dif <- f1 / (f0 + f1)
  # Posterior of delta within each component (normal-normal), then mixed.
  e0 <- t0^2 / v0 * (d - c0); s0 <- t0^2 * se^2 / v0
  e1 <- m1 + t1^2 / v1 * (d - c0 - m1); s1 <- t1^2 * se^2 / v1
  dif_mean <- (1 - p_dif) * e0 + p_dif * e1
  dif_sd <- sqrt((1 - p_dif) * (s0 + e0^2) + p_dif * (s1 + e1^2) - dif_mean^2)
  lfdr <- 1 - p_dif
  ord <- order(lfdr)
  k <- max(c(0, which(cumsum(lfdr[ord]) / seq_along(ord) <= fdr)))
  flag <- rep(FALSE, length(d)); flag[ord[seq_len(k)]] <- TRUE

  # Baselines: all items as anchors, and iterative purification.
  keep <- rep(TRUE, length(d))
  for (i in 1:20) {
    cp <- stats::weighted.mean(d[keep], 1 / se[keep]^2)
    new <- abs(d - cp) / se < stats::qnorm(0.975)
    if (identical(new, keep) || sum(new) < 3) break
    keep <- new
  }
  # pi0 at its lower bound means the data cannot separate a DIF-free majority
  # from the DIF cluster: the linking shift and flags are then unreliable.
  weak <- p0 < 0.52
  if (weak)
    warning("Estimated DIF-free share is at the 0.5 identification bound: linking is weakly ",
            "identified. Compare with the purified linking (c_purified = ", round(cp, 3),
            ") and treat flags with caution.", call. = FALSE)
  structure(list(
    weakly_identified = weak,
    items = data.frame(item = it$item, d = d, se_d = se, p_dif = p_dif, lfdr = lfdr,
                       dif_mean = dif_mean, dif_sd = dif_sd, flag = flag,
                       anchor = p_dif < anchor_max, stringsAsFactors = FALSE),
    link = c(c = c0, c_se = c_se, pi0 = p0, m1 = m1, tau0 = t0, tau1 = t1),
    c_mean = stats::weighted.mean(d, 1 / se^2), c_purified = cp,
    fdr = fdr, calibration = calibration), class = "td_dif")
}

#' @export
print.td_dif <- function(x, ...) {
  l <- x$link
  cat(sprintf("<td_dif> %d items | linking shift c = %.3f (SE %.3f); mean-linking c = %.3f\n",
              nrow(x$items), l[["c"]], l[["c_se"]], x$c_mean))
  cat(sprintf("estimated DIF-free share %.2f; DIF component mean %+.2f, SD %.2f\n",
              l[["pi0"]], l[["m1"]], l[["tau1"]]))
  cat(sum(x$items$flag), "items flagged at Bayesian FDR", x$fdr, "|", sum(x$items$anchor),
      "clean anchors\n")
  if (isTRUE(x$weakly_identified))
    cat(sprintf("WARNING: weakly identified (DIF-free share at the 0.5 bound); purified linking c = %.3f\n",
                x$c_purified))
  cat("\n")
  f <- x$items[x$items$flag, c("item", "d", "p_dif", "dif_mean", "dif_sd")]
  if (nrow(f)) print(f[order(-abs(f$dif_mean)), ], digits = 3, row.names = FALSE)
  invisible(x)
}

#' Mantel-Haenszel DIF with purification (conventional baseline)
#'
#' @param responses 0/1 matrix.
#' @param group Group label per person.
#' @param ref,focal Group labels.
#' @param fdr Benjamini-Hochberg level for flagging.
#' @param purify Re-run once matching on the total over non-flagged items.
#' @return Data frame: `item`, `alpha_mh`, `delta_mh` (ETS delta scale),
#'   `p_value`, `flag`.
#' @examples
#' sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
#' mh <- td_mh(sim$responses, sim$group)
#' table(flagged = mh$flag, true_dif = sim$truth$dif_item)
#' @export
td_mh <- function(responses, group, ref = "ref", focal = "focal", fdr = 0.1, purify = TRUE) {
  X <- as.matrix(responses); fo <- group == focal; re <- group == ref
  run <- function(anchor) {
    t(vapply(seq_len(ncol(X)), function(i) {
      a <- anchor; a[i] <- TRUE
      s <- rowSums(X[, a, drop = FALSE])
      num <- den <- sa <- ea <- va <- 0
      for (k in unique(s)) {
        in_k <- s == k
        A <- sum(X[in_k & re, i]); B <- sum(in_k & re) - A
        C <- sum(X[in_k & fo, i]); D <- sum(in_k & fo) - C
        N <- A + B + C + D
        if (N < 2 || (A + B) == 0 || (C + D) == 0) next
        num <- num + A * D / N; den <- den + B * C / N
        m1 <- A + C; m0 <- B + D
        sa <- sa + A; ea <- ea + (A + B) * m1 / N
        va <- va + (A + B) * (C + D) * m1 * m0 / (N^2 * (N - 1))
      }
      alpha <- (num + 0.5) / (den + 0.5)
      chi <- (abs(sa - ea) - 0.5)^2 / va
      c(alpha, stats::pchisq(chi, 1, lower.tail = FALSE))
    }, numeric(2)))
  }
  res <- run(rep(TRUE, ncol(X)))
  flag <- stats::p.adjust(res[, 2], "BH") < fdr
  if (purify && any(flag) && sum(!flag) > 2) {
    res <- run(!flag)
    flag <- stats::p.adjust(res[, 2], "BH") < fdr
  }
  data.frame(item = colnames(X), alpha_mh = res[, 1], delta_mh = -2.35 * log(res[, 1]),
             p_value = res[, 2], flag = flag, stringsAsFactors = FALSE)
}
