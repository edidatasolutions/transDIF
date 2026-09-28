# Negative marginal log-likelihood of the spike-and-slab model.
# par = (c, m1, log tau0, log tau1, logit pi0); pi0 is the DIF-free share.
mix_nll <- function(par, d, se) {
  c0 <- par[1]; m1 <- par[2]; t0 <- exp(par[3]); t1 <- exp(par[4])
  p0 <- stats::plogis(par[5])
  f0 <- stats::dnorm(d, c0, sqrt(se^2 + t0^2))
  f1 <- stats::dnorm(d, c0 + m1, sqrt(se^2 + t1^2))
  -sum(log(p0 * f0 + (1 - p0) * f1 + 1e-300))
}

# Precision-weighted mode of the item differences: the c maximizing
# F(c) = sum_i phi((d_i - c) / s_i) / s_i, a strongly redescending
# M-estimator that locates the densest cluster of items. Returns the mode,
# its sandwich SE, and the best competing local mode.
link_mode <- function(d, s) {
  f <- function(c) sum(stats::dnorm((c - d) / s) / s)
  g <- seq(min(d) - 0.5, max(d) + 0.5, length.out = 2001)
  fg <- vapply(g, f, 0)
  h <- g[2] - g[1]
  peaks <- which(diff(sign(diff(fg))) == -2) + 1
  if (!length(peaks)) peaks <- which.max(fg)
  refine <- function(i) stats::optimize(f, c(g[i] - h, g[i] + h), maximum = TRUE, tol = 1e-10)
  top <- peaks[order(-fg[peaks])]
  m <- refine(top[1])
  c0 <- m$maximum
  r <- (d - c0) / s
  psi <- stats::dnorm(r) * r / s^2            # contributions to F'(c)
  dpsi <- stats::dnorm(r) * (r^2 - 1) / s^3   # contributions to F''(c)
  alt <- if (length(top) > 1) refine(top[2]) else NULL
  list(c = c0, se = sqrt(sum(psi^2)) / abs(sum(dpsi)),
       alt_c = if (is.null(alt)) NA_real_ else alt$maximum,
       alt_ratio = if (is.null(alt)) 0 else alt$objective / m$objective)
}

#' Robust linking, anchor selection and small-sample DIF
#'
#' The between-language difference of item `i` is modeled as
#' `d_i ~ N(c + delta_i, se_i^2)`, where `c` is the common shift (the ability
#' difference) that linking must recover and `delta_i` is the item's DIF.
#'
#' **Linking.** By default `c` is the precision-weighted *mode* of the `d_i`:
#' the center of the densest cluster of items, found by maximizing
#' `sum_i phi((d_i - c) / s_i) / s_i` with `s_i^2 = se_i^2 + tau0^2`. It
#' assumes that DIF-free items form the largest cluster, not that DIF cancels
#' out as mean linking does. In known-truth benchmarks across balanced,
#' directional and heavy DIF, it had the lowest overall RMSE of the
#' estimators compared (including mean linking, iterative purification,
#' median, Tukey biweight, least trimmed squares and the joint mixture below).
#' Its SE is a sandwich estimate plus the scales' location variance. If a
#' second cluster of items is nearly as dense, the linking is flagged as
#' ambiguous and the competing shift is reported.
#'
#' **DIF.** Given `c`, DIF effects follow a spike-and-slab mixture:
#' DIF-free items (share `pi0 > 0.5`) have `delta_i ~ N(0, tau0^2)`, and DIF
#' items have `delta_i ~ N(m1, tau1^2)`, where `m1` allows directional DIF.
#' Each item gets a posterior DIF probability, a shrunken DIF estimate and a
#' local false discovery rate. `link = "mixture"` instead estimates `c` jointly
#' in the mixture (the approach of version 0.1.0; kept for comparison).
#'
#' @param calibration A `td_calibration`.
#' @param fdr Target Bayesian false discovery rate for flagging.
#' @param tau0 SD of DIF among "DIF-free" items: the scale of DIF considered
#'   negligible (logits).
#' @param anchor_max Items with posterior DIF probability below this are
#'   reported as anchors.
#' @param link `"mode"` (default) or `"mixture"`.
#' @param ambiguity Competing-mode density ratio above which the linking is
#'   reported as ambiguous.
#' @return A `td_dif` object: `$items` (`item`, `d`, `se_d`, `p_dif`, `lfdr`,
#'   `dif_mean`, `dif_sd` (posterior mean/SD of DIF), `flag`, `anchor`),
#'   `$link` (`c`, `c_se`, `pi0`, `m1`, `tau0`, `tau1`, `alt_c`, `alt_ratio`),
#'   baseline linking constants `c_mean` (all items as anchors) and
#'   `c_purified`, and `weakly_identified` (TRUE, with a warning, when a
#'   second item cluster is nearly as dense as the chosen one).
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' dif
#' # true linking shift is -focal_mean = 0.5
#' c(estimate = dif$link[["c"]], mean_linking = dif$c_mean)
#' @export
td_dif <- function(calibration, fdr = 0.1, tau0 = 0.05, anchor_max = 0.2,
                   link = c("mode", "mixture"), ambiguity = 0.8) {
  link <- match.arg(link)
  it <- calibration$items
  d <- it$d; se <- it$se_d
  lm <- link_mode(d, sqrt(se^2 + tau0^2))
  pi0_q <- function(q) stats::qlogis(0.5 + 0.5 * stats::plogis(q))  # keeps pi0 > 0.5
  fit_best <- function(starts, obj) {
    best <- NULL
    for (s in starts) {
      o <- tryCatch(stats::optim(s, obj, method = "BFGS", hessian = TRUE,
                                 control = list(maxit = 1000)), error = function(e) NULL)
      if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o
    }
    best
  }
  if (link == "mode") {
    # Mixture for DIF given the linking shift: q = (m1, log(tau1 - tau0), pi0 logit).
    c0 <- lm$c
    wrap <- function(q) c(c0, q[1], log(tau0), log(tau0 + exp(q[2])), pi0_q(q[3]))
    best <- fit_best(list(c(0.5, log(0.4), 0.5), c(-0.5, log(0.4), 0.5), c(0, log(0.8), 1.5)),
                     function(q) mix_nll(wrap(q), d, se))
    c_se <- sqrt(lm$se^2 + calibration$loc_var)
  } else {
    # Joint mixture: q = (c, m1, log(tau1 - tau0), pi0 logit).
    wrap <- function(q) c(q[1], q[2], log(tau0), log(tau0 + exp(q[3])), pi0_q(q[4]))
    cs <- stats::quantile(d, seq(0.2, 0.8, by = 0.1), names = FALSE)
    best <- fit_best(c(lapply(cs, function(c0) c(c0, 0.5, log(0.4), 0.5)),
                       lapply(cs, function(c0) c(c0, -0.5, log(0.4), 0.5))),
                     function(q) mix_nll(wrap(q), d, se))
    c_se <- tryCatch(sqrt(solve(best$hessian)[1, 1] + calibration$loc_var),
                     error = function(e) NA_real_)
  }
  par <- wrap(best$par)
  c0 <- par[1]; m1 <- par[2]; t0 <- exp(par[3]); t1 <- exp(par[4]); p0 <- stats::plogis(par[5])

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
  # Two item clusters of similar density: the data cannot say which one is
  # the DIF-free majority, so the linking (and every DIF estimate) is ambiguous.
  weak <- link == "mode" && lm$alt_ratio >= ambiguity
  if (weak)
    warning(sprintf(paste0("Linking is ambiguous: a second cluster of items at c = %.3f is ",
                           "%.0f%% as dense as the chosen one (c = %.3f). Review items in both ",
                           "clusters with translation experts before relying on DIF flags."),
                    lm$alt_c, 100 * lm$alt_ratio, c0), call. = FALSE)
  structure(list(
    weakly_identified = weak,
    items = data.frame(item = it$item, d = d, se_d = se, p_dif = p_dif, lfdr = lfdr,
                       dif_mean = dif_mean, dif_sd = dif_sd, flag = flag,
                       anchor = p_dif < anchor_max, stringsAsFactors = FALSE),
    link = c(c = c0, c_se = c_se, pi0 = p0, m1 = m1, tau0 = t0, tau1 = t1,
             alt_c = lm$alt_c, alt_ratio = lm$alt_ratio),
    method = link,
    c_mean = stats::weighted.mean(d, 1 / se^2), c_purified = cp,
    fdr = fdr, calibration = calibration), class = "td_dif")
}

#' @export
print.td_dif <- function(x, ...) {
  l <- x$link
  cat(sprintf("<td_dif> %d items | linking shift c = %.3f (SE %.3f, %s); mean-linking c = %.3f\n",
              nrow(x$items), l[["c"]], l[["c_se"]], x$method, x$c_mean))
  cat(sprintf("estimated DIF-free share %.2f; DIF component mean %+.2f, SD %.2f\n",
              l[["pi0"]], l[["m1"]], l[["tau1"]]))
  cat(sum(x$items$flag), "items flagged at Bayesian FDR", x$fdr, "|", sum(x$items$anchor),
      "clean anchors\n")
  if (isTRUE(x$weakly_identified))
    cat(sprintf("WARNING: ambiguous linking; a second item cluster at c = %.3f is %.0f%% as dense\n",
                l[["alt_c"]], 100 * l[["alt_ratio"]]))
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
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
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
