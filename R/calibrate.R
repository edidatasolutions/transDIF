# Rasch marginal ML for one group: theta ~ N(0, sigma^2), difficulties free.
# EM with Newton M-steps; standard errors from a numerical Jacobian of the
# exact marginal score (Fisher identity), so they include the uncertainty
# about each person's ability. The complete-data information would overstate
# precision, and SEs drive DIF inference.
# A weak N(0, b_prior_sd^2) penalty keeps items that a small group answers
# all-correct or all-wrong finite; it is negligible otherwise.
rasch_mml <- function(X, grid = seq(-6, 6, by = 0.1), max_iter = 500, tol = 1e-6,
                      b_prior_sd = 4) {
  X <- as.matrix(X)
  p <- pmin(pmax(colMeans(X), 0.01), 0.99)
  b <- -stats::qlogis(p); sigma <- 1
  pen <- 1 / b_prior_sd^2
  score <- function(b, sigma) {
    P <- stats::plogis(outer(grid, b, "-"))
    LL <- X %*% t(log(P)) + (1 - X) %*% t(log(1 - P))
    LL <- sweep(LL, 2, stats::dnorm(grid, 0, sigma, log = TRUE), "+")
    W <- exp(LL - apply(LL, 1, max)); W <- W / rowSums(W)
    nk <- colSums(W); r <- crossprod(W, X)
    list(P = P, nk = nk, r = r, grad = colSums(nk * P - r) - pen * b)
  }
  for (it in seq_len(max_iter)) {
    s <- score(b, sigma)
    step <- (colSums(s$r - s$nk * s$P) + pen * b) / (colSums(s$nk * s$P * (1 - s$P)) + pen)
    b <- b - pmax(pmin(step, 1), -1)
    sigma_new <- sqrt(sum(s$nk * grid^2) / nrow(X))
    if (max(abs(step), abs(sigma_new - sigma)) < tol) { sigma <- sigma_new; break }
    sigma <- sigma_new
  }
  h <- 1e-4
  H <- vapply(seq_along(b), function(i) {
    bp <- b; bp[i] <- b[i] + h; bm <- b; bm[i] <- b[i] - h
    (score(bp, sigma)$grad - score(bm, sigma)$grad) / (2 * h)
  }, numeric(length(b)))
  H <- (H + t(H)) / 2                  # Hessian of the log-likelihood (negative definite)
  V <- solve(-H)
  # With the ability mean fixed at 0, every b_i shares the uncertainty of the
  # scale's location. Between-group comparisons absorb that common part into
  # the linking shift, so DIF uses relative SEs (of b_i - mean(b)), and the
  # location variance is carried separately into the linking SE.
  I <- length(b); C <- diag(I) - 1 / I
  list(b = stats::setNames(b, colnames(X)), se = stats::setNames(sqrt(diag(V)), colnames(X)),
       se_rel = stats::setNames(sqrt(diag(C %*% V %*% C)), colnames(X)),
       loc_var = sum(V) / I^2, sigma = sigma, n = nrow(X), iterations = it)
}

#' Calibrate each language group separately
#'
#' Fits the Rasch model by marginal maximum likelihood within each group, each
#' with its own mean-zero ability scale. The between-language difference
#' `d = b_focal - b_ref` therefore equals item DIF plus a common shift
#' `c = -(focal mean ability on the reference scale)`. Separating the two is
#' the linking problem [td_dif()] solves.
#'
#' @param responses 0/1 matrix (persons x items), column names = item ids.
#' @param group Group label per person.
#' @param ref,focal Labels of the reference (source-language) and focal
#'   (translated) groups.
#' @return An `td_calibration`: data frame `items` (`item`, `b_ref`, `se_ref`,
#'   `b_focal`, `se_focal`, `d`, `se_d`) plus group sizes, ability SDs and
#'   `loc_var` (variance of the two scales' locations). `se_ref`/`se_focal`
#'   are absolute SEs; `se_d` uses relative SEs, excluding the location
#'   uncertainty that is common to all items (it belongs to the linking shift).
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' cal <- td_calibrate(sim$responses, sim$group)
#' head(cal$items)
#' @export
td_calibrate <- function(responses, group, ref = "ref", focal = "focal") {
  X <- as.matrix(responses)
  if (is.null(colnames(X))) colnames(X) <- sprintf("item%02d", seq_len(ncol(X)))
  if (anyNA(X)) stop("Missing responses are not supported yet.")
  if (!all(X %in% 0:1)) stop("Responses must be 0/1.")
  r <- rasch_mml(X[group == ref, , drop = FALSE])
  f <- rasch_mml(X[group == focal, , drop = FALSE])
  items <- data.frame(item = colnames(X), b_ref = r$b, se_ref = r$se,
                      b_focal = f$b, se_focal = f$se, stringsAsFactors = FALSE)
  items$d <- items$b_focal - items$b_ref
  items$se_d <- sqrt(r$se_rel^2 + f$se_rel^2)
  rownames(items) <- NULL
  structure(list(items = items, n_ref = r$n, n_focal = f$n,
                 sigma_ref = r$sigma, sigma_focal = f$sigma,
                 loc_var = r$loc_var + f$loc_var), class = "td_calibration")
}
