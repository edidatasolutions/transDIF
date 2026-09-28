#' Simulate a source-language and a translated administration with known DIF
#'
#' Items carry binary adaptation features (idiom, cultural referent,
#' measurement units, high vocabulary load). In the translated form an item's
#' difficulty shifts by `sum(feature_effects * features)` plus small noise, so
#' DIF is directional (translations mostly harder) and unbalanced, which is
#' the case where mean-based linking fails. The focal (translated) group is
#' small and lower-scoring on average.
#'
#' @param n_ref,n_focal Group sizes.
#' @param n_items Test length.
#' @param focal_mean,focal_sd Focal-group ability (reference is N(0, 1)).
#' @param feature_prev Prevalence of each feature.
#' @param feature_effects DIF (logits) contributed by each feature.
#' @param dif_noise SD of feature-unrelated DIF on flagged items.
#' @param seed Optional seed.
#' @return An `td_sim`: `$responses` (0/1 matrix, persons x items), `$group`
#'   (`"ref"`/`"focal"`), `$features` (item data frame), `$truth` (`b_ref`,
#'   `dif`, `focal_mean`, `focal_sd`).
#' @examples
#' sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
#' table(dif_item = sim$truth$dif_item)
#' head(sim$features)
#' @export
td_simulate <- function(n_ref = 2000, n_focal = 150, n_items = 60,
                        focal_mean = -0.5, focal_sd = 1,
                        feature_prev = c(idiom = 0.1, cultural = 0.1, units = 0.08, vocabulary = 0.12),
                        feature_effects = c(idiom = 0.6, cultural = 0.5, units = -0.4, vocabulary = 0.35),
                        dif_noise = 0.1, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  items <- sprintf("Q%02d", seq_len(n_items))
  Fm <- vapply(feature_prev, function(p) stats::rbinom(n_items, 1, p), numeric(n_items))
  Fm <- matrix(Fm, n_items, dimnames = list(items, names(feature_prev)))
  any_f <- rowSums(Fm) > 0
  dif <- drop(Fm %*% feature_effects[colnames(Fm)]) + any_f * stats::rnorm(n_items, 0, dif_noise)
  b <- stats::rnorm(n_items, 0, 1)
  th <- c(stats::rnorm(n_ref), stats::rnorm(n_focal, focal_mean, focal_sd))
  group <- rep(c("ref", "focal"), c(n_ref, n_focal))
  B <- matrix(b, length(th), n_items, byrow = TRUE)
  B[group == "focal", ] <- B[group == "focal", ] + matrix(dif, n_focal, n_items, byrow = TRUE)
  X <- matrix(stats::rbinom(length(B), 1, stats::plogis(th - B)), length(th),
              dimnames = list(NULL, items))
  structure(list(
    responses = X, group = group,
    features = data.frame(item = items, as.data.frame(Fm), stringsAsFactors = FALSE),
    truth = list(b_ref = stats::setNames(b, items), dif = stats::setNames(dif, items),
                 dif_item = stats::setNames(any_f, items),
                 focal_mean = focal_mean, focal_sd = focal_sd)
  ), class = "td_sim")
}
