# Raw-score distribution at each theta (Lord-Wingersky recursion).
lw_dist <- function(theta, b) {
  D <- matrix(1, length(theta), 1)
  for (bi in b) {
    p <- stats::plogis(theta - bi)
    D <- cbind(D * (1 - p), 0) + cbind(0, D * p)
  }
  D
}

pass_rate <- function(b, cut, mean, sd, nodes) {
  th <- mean + sd * nodes
  D <- lw_dist(th, b)
  mean(rowSums(D[, (cut + 1):ncol(D), drop = FALSE]))
}

#' Does item-level DIF add up to different pass rates?
#'
#' Differential test functioning for the translated form. With difficulties on
#' the reference scale (`b_ref`) and DIF effects `delta`, the translated form
#' has difficulties `b_ref + delta`. For the translated-language population
#' (ability N(-c, sigma_focal^2) on the reference scale) the function computes
#' the pass rate at raw cut `cut` on the translated form versus on a DIF-free
#' form, using exact score distributions. It also computes the expected
#' raw-score shift for an examinee exactly at the cut. Intervals propagate
#' both the linking uncertainty (the focal group's mean ability is `-c`) and
#' the posterior uncertainty of each item's DIF.
#'
#' @param dif An `td_dif`.
#' @param cut Raw-score passing standard.
#' @param n_draws Posterior draws.
#' @param level Interval level.
#' @param seed Optional seed.
#' @return A data frame with estimate and interval for `pass_rate_fair`,
#'   `pass_rate_translated`, `pass_rate_change` and `score_shift_at_cut`.
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' td_impact(dif, cut = 12, n_draws = 50, seed = 1)
#' @export
td_impact <- function(dif, cut, n_draws = 200, level = 0.9, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  cal <- dif$calibration
  b <- cal$items$b_ref
  mu <- -dif$link[["c"]]; s <- cal$sigma_focal
  nodes <- stats::qnorm(stats::ppoints(61))
  it <- dif$items
  th_cut <- stats::uniroot(function(t) sum(stats::plogis(t - b)) - cut, c(-10, 10))$root
  one <- function(delta) {
    c(pass_rate_fair = pass_rate(b, cut, mu, s, nodes),
      pass_rate_translated = pass_rate(b + delta, cut, mu, s, nodes),
      score_shift_at_cut = sum(stats::plogis(th_cut - b - delta)) - cut)
  }
  est <- one(it$dif_mean)
  # Each draw takes a linking shift c from its sampling distribution (the
  # focal mean is -c, so linking error moves the pass rate directly), then
  # draws every item's DIF from its two-component posterior given that c.
  l <- dif$link; se <- it$se_d
  v0 <- se^2 + l[["tau0"]]^2; v1 <- se^2 + l[["tau1"]]^2
  s0 <- sqrt(l[["tau0"]]^2 * se^2 / v0); s1 <- sqrt(l[["tau1"]]^2 * se^2 / v1)
  draws <- t(replicate(n_draws, {
    cd <- stats::rnorm(1, l[["c"]], l[["c_se"]])
    f0 <- l[["pi0"]] * stats::dnorm(it$d, cd, sqrt(v0))
    f1 <- (1 - l[["pi0"]]) * stats::dnorm(it$d, cd + l[["m1"]], sqrt(v1))
    k <- stats::runif(nrow(it)) < f1 / (f0 + f1)
    e0 <- l[["tau0"]]^2 / v0 * (it$d - cd)
    e1 <- l[["m1"]] + l[["tau1"]]^2 / v1 * (it$d - cd - l[["m1"]])
    delta <- ifelse(k, stats::rnorm(nrow(it), e1, s1), stats::rnorm(nrow(it), e0, s0))
    c(pass_rate_fair = pass_rate(b, cut, -cd, s, nodes),
      pass_rate_translated = pass_rate(b + delta, cut, -cd, s, nodes),
      score_shift_at_cut = sum(stats::plogis(th_cut - b - delta)) - cut)
  }))
  draws <- cbind(draws, pass_rate_change = draws[, 2] - draws[, 1])
  est <- c(est, pass_rate_change = est[[2]] - est[[1]])
  a <- (1 - level) / 2
  q <- apply(draws, 2, stats::quantile, c(a, 1 - a))
  nm <- c("pass_rate_fair", "pass_rate_translated", "pass_rate_change", "score_shift_at_cut")
  data.frame(quantity = nm, estimate = est[nm], lower = q[1, nm], upper = q[2, nm],
             row.names = NULL)
}

#' Which item features predict DIF?
#'
#' Random-effects meta-regression of each item's DIF estimate (`d - c`) on
#' item features (e.g. idioms, cultural referents, measurement units,
#' vocabulary load), weighting by `1 / (se_d^2 + tau^2)`. The between-item
#' variance `tau^2` not explained by the features is estimated by the method
#' of moments. Coefficients are logits of DIF per unit of the feature. That is
#' guidance a translation team can act on.
#'
#' @param dif An `td_dif`.
#' @param features Data frame with `item` and numeric feature columns.
#' @return Data frame of coefficients (`term`, `estimate`, `se`, `z`,
#'   `p_value`) with attribute `tau` (residual DIF SD). Features with no
#'   variation across items are dropped with a warning.
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' td_features(dif, sim$features)
#' @export
td_features <- function(dif, features) {
  it <- dif$items
  f <- features[match(it$item, features$item), setdiff(names(features), "item"), drop = FALSE]
  if (anyNA(f)) stop("Every item needs feature values.")
  # A feature present on no item (or on every item) has no information and
  # makes the regression singular: drop it and say so.
  constant <- vapply(f, function(col) length(unique(col)) < 2, logical(1))
  if (any(constant))
    warning("Dropped features with no variation across items: ",
            paste(names(f)[constant], collapse = ", "), call. = FALSE)
  f <- f[!constant]
  X <- cbind(`(Intercept)` = 1, as.matrix(f))
  if (qr(X)$rank < ncol(X))
    stop("Item features are collinear (e.g. two features always occur together); ",
         "combine or drop some before calling td_features().", call. = FALSE)
  y <- it$d - dif$link[["c"]]; v <- it$se_d^2
  wls <- function(w) {
    XtW <- t(X * w)
    cov <- solve(XtW %*% X)
    list(beta = drop(cov %*% XtW %*% y), cov = cov)
  }
  w <- 1 / v
  f0 <- wls(w)
  Q <- sum(w * (y - X %*% f0$beta)^2)
  trace_term <- sum(w) - sum(diag(f0$cov %*% t(X * w^2) %*% X))
  tau2 <- max(0, (Q - (nrow(X) - ncol(X))) / trace_term)
  f1 <- wls(1 / (v + tau2))
  se <- sqrt(diag(f1$cov))
  out <- data.frame(term = colnames(X), estimate = f1$beta, se = se, z = f1$beta / se,
                    p_value = 2 * stats::pnorm(-abs(f1$beta / se)), row.names = NULL)
  structure(out, tau = sqrt(tau2))
}

#' Draft a comparability report
#'
#' Assembles a plain-language Markdown report of the linking, DIF, aggregate
#' impact and feature analyses, organized around the kinds of evidence the
#' Standards for Educational and Psychological Testing (2014; fairness
#' chapter) and the ITC Guidelines for Translating and Adapting Tests (2nd ed.,
#' 2017) ask for. It is a draft for a psychometrician to review, not a
#' finished validity argument.
#'
#' @param dif An `td_dif`.
#' @param impact Optional output of [td_impact()].
#' @param features Optional output of [td_features()].
#' @param languages Names of the source and target languages.
#' @param file Optional path to write the Markdown to.
#' @param sensitivity Optional output of [td_sensitivity()]; adds a section on
#'   how the conclusions depend on the linking assumption.
#' @return The report as a character string (invisibly if written to file).
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' dif <- td_dif(td_calibrate(sim$responses, sim$group))
#' rep <- td_report(dif, td_impact(dif, cut = 12, n_draws = 50, seed = 1),
#'                  td_features(dif, sim$features), c("English", "French"),
#'                  sensitivity = td_sensitivity(dif, B = 50, seed = 1))
#' cat(rep)
#' # To save: td_report(dif, file = file.path(tempdir(), "comparability.md"))
#' @export
td_report <- function(dif, impact = NULL, features = NULL,
                      languages = c("source", "target"), file = NULL, sensitivity = NULL) {
  cal <- dif$calibration; l <- dif$link; it <- dif$items
  fl <- it[it$flag, ]
  fl <- fl[order(-abs(fl$dif_mean)), ]
  pct <- function(x) sprintf("%.1f%%", 100 * x)
  lines <- c(
    sprintf("# Score comparability: %s vs %s forms", languages[1], languages[2]), "",
    "## Samples",
    sprintf("- %s: %d examinees; %s: %d examinees.", languages[1], cal$n_ref, languages[2], cal$n_focal),
    "", "## Linking and anchors",
    sprintf("- The %s group's mean ability is estimated at %.2f logits relative to the %s group (SE %.2f).",
            languages[2], -l[["c"]], languages[1], l[["c_se"]]),
    sprintf("- This estimate relies on DIF-free items forming the largest cluster of items (estimated DIF-free share: %s), not on DIF cancelling out. Linking with all items as anchors would have given %.2f.",
            pct(l[["pi0"]]), -dif$c_mean),
    sprintf("- %d items qualify as clean anchors (posterior DIF probability below 0.2).", sum(it$anchor)),
    if (isTRUE(dif$weakly_identified))
      sprintf("- **Caution:** a second cluster of items, implying a mean ability of %.2f, is %.0f%% as dense as the chosen one, so the linking is ambiguous. Review items in both clusters with translation experts before relying on these results.",
              -l[["alt_c"]], 100 * l[["alt_ratio"]]),
    "", "## Item-level DIF",
    sprintf("- %d of %d items are flagged (Bayesian false discovery rate %s).", nrow(fl), nrow(it), pct(dif$fdr)))
  if (nrow(fl)) {
    lines <- c(lines, "", "| item | DIF (logits) | posterior SD | P(DIF) | direction |", "|---|---|---|---|---|",
               sprintf("| %s | %+.2f | %.2f | %.2f | %s |", fl$item, fl$dif_mean, fl$dif_sd, fl$p_dif,
                       ifelse(fl$dif_mean > 0, paste("harder in", languages[2]),
                              paste("easier in", languages[2]))))
  }
  if (!is.null(impact)) {
    g <- function(q) impact[impact$quantity == q, ]
    ch <- g("pass_rate_change"); sh <- g("score_shift_at_cut")
    lines <- c(lines, "", "## Aggregate impact",
      sprintf("- Expected pass rate of the %s group: %s on the translated form vs %s on a DIF-free form; change %+.1f points (90%% interval %+.1f to %+.1f).",
              languages[2], pct(g("pass_rate_translated")$estimate), pct(g("pass_rate_fair")$estimate),
              100 * ch$estimate, 100 * ch$lower, 100 * ch$upper),
      sprintf("- An examinee exactly at the cut is expected to score %+.2f raw points on the translated form (interval %+.2f to %+.2f).",
              sh$estimate, sh$lower, sh$upper))
  }
  if (!is.null(sensitivity)) {
    s <- sensitivity; lk <- s$linkings
    lab <- c(mode = "densest item cluster (mode)", purified = "iterative purification",
             all_items = "all items as anchors")
    has_imp <- "pass_rate_change" %in% names(lk)
    lines <- c(lines, "", "## Sensitivity to the linking assumption",
      if (s$verdict == "robust")
        sprintf("- **Robust:** the linking assumptions agree within %.2f logits, and %.0f%% of %d bootstrap re-estimates of the mode fall within %.2f logits of the estimate.",
                s$range, 100 * s$bootstrap[["share_within"]], s$B, s$tolerance)
      else
        sprintf("- **Sensitive:** the conclusions depend on which items are assumed DIF-free. The linking assumptions differ by up to %.2f logits, and only %.0f%% of %d bootstrap re-estimates of the mode fall within %.2f logits of the estimate. Report the results under each assumption, and let expert item review decide which items anchor the scale.",
                s$range, 100 * s$bootstrap[["share_within"]], s$B, s$tolerance),
      "",
      if (has_imp) "| linking assumption | mean ability of the %s group | items flagged | pass-rate change |" else
        "| linking assumption | mean ability of the %s group | items flagged |",
      if (has_imp) "|---|---|---|---|" else "|---|---|---|",
      if (has_imp)
        sprintf("| %s | %.2f (SE %.2f) | %d | %+.1f points (%+.1f to %+.1f) |", lab[lk$assumption],
                lk$focal_mean, lk$se, lk$n_flagged, 100 * lk$pass_rate_change,
                100 * lk$change_lower, 100 * lk$change_upper)
      else sprintf("| %s | %.2f (SE %.2f) | %d |", lab[lk$assumption], lk$focal_mean, lk$se, lk$n_flagged))
    lines <- sub("%s group", paste(languages[2], "group"), lines, fixed = TRUE)
    si <- s$items$item[s$items$linking_sensitive]
    lines <- c(lines, "",
      if (length(si))
        sprintf("- Items whose DIF verdict depends on the linking (review these first): %s.", paste(si, collapse = ", "))
      else "- No item's DIF verdict depends on the linking assumption.")
  }
  if (!is.null(features)) {
    fe <- features[features$term != "(Intercept)", ]
    fe <- fe[order(fe$p_value), ]
    lines <- c(lines, "", "## What predicts DIF (guidance for translators)",
      "| feature | DIF per feature (logits) | SE | p |", "|---|---|---|---|",
      sprintf("| %s | %+.2f | %.2f | %.3f |", fe$term, fe$estimate, fe$se, fe$p_value),
      "", sprintf("Residual DIF SD not explained by features: %.2f logits.", attr(features, "tau")))
  }
  lines <- c(lines, "", "## Notes for review",
    "- Flagged items call for expert review of the translation before any statistical adjustment.",
    "- Conclusions assume the Rasch model holds in both groups and that DIF-free items form the largest cluster of items; td_sensitivity() shows how much they depend on that assumption.",
    "- Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).")
  txt <- paste(lines, collapse = "\n")
  if (!is.null(file)) { writeLines(txt, file); return(invisible(txt)) }
  txt
}
