# Robust linking, anchor selection and small-sample DIF

The between-language difference of item \`i\` is modeled as \`d_i ~
N(c + delta_i, se_i^2)\`, where \`c\` is the common shift (the ability
difference) that linking must recover and \`delta_i\` is the item's DIF.

## Usage

``` r
td_dif(
  calibration,
  fdr = 0.1,
  tau0 = 0.05,
  anchor_max = 0.2,
  link = c("mode", "mixture"),
  ambiguity = 0.8
)
```

## Arguments

- calibration:

  A \`td_calibration\`.

- fdr:

  Target Bayesian false discovery rate for flagging.

- tau0:

  SD of DIF among "DIF-free" items: the scale of DIF considered
  negligible (logits).

- anchor_max:

  Items with posterior DIF probability below this are reported as
  anchors.

- link:

  \`"mode"\` (default) or \`"mixture"\`.

- ambiguity:

  Competing-mode density ratio above which the linking is reported as
  ambiguous.

## Value

A \`td_dif\` object: \`\$items\` (\`item\`, \`d\`, \`se_d\`, \`p_dif\`,
\`lfdr\`, \`dif_mean\`, \`dif_sd\` (posterior mean/SD of DIF), \`flag\`,
\`anchor\`), \`\$link\` (\`c\`, \`c_se\`, \`pi0\`, \`m1\`, \`tau0\`,
\`tau1\`, \`alt_c\`, \`alt_ratio\`), baseline linking constants
\`c_mean\` (all items as anchors) and \`c_purified\`, and
\`weakly_identified\` (TRUE, with a warning, when a second item cluster
is nearly as dense as the chosen one).

## Details

\*\*Linking.\*\* By default \`c\` is the precision-weighted \*mode\* of
the \`d_i\`: the center of the densest cluster of items, found by
maximizing \`sum_i phi((d_i - c) / s_i) / s_i\` with \`s_i^2 = se_i^2 +
tau0^2\`. It assumes that DIF-free items form the largest cluster, not
that DIF cancels out as mean linking does. In known-truth benchmarks
across balanced, directional and heavy DIF, it had the lowest overall
RMSE of the estimators compared (including mean linking, iterative
purification, median, Tukey biweight, least trimmed squares and the
joint mixture below). Its SE is a sandwich estimate plus the scales'
location variance. If a second cluster of items is nearly as dense, the
linking is flagged as ambiguous and the competing shift is reported.

\*\*DIF.\*\* Given \`c\`, DIF effects follow a spike-and-slab mixture:
DIF-free items (share \`pi0 \> 0.5\`) have \`delta_i ~ N(0, tau0^2)\`,
and DIF items have \`delta_i ~ N(m1, tau1^2)\`, where \`m1\` allows
directional DIF. Each item gets a posterior DIF probability, a shrunken
DIF estimate and a local false discovery rate. \`link = "mixture"\`
instead estimates \`c\` jointly in the mixture (the approach of version
0.1.0; kept for comparison).

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
dif
#> <td_dif> 20 items | linking shift c = 0.616 (SE 0.246, mode); mean-linking c = 0.610
#> estimated DIF-free share 0.50; DIF component mean -0.02, SD 0.39
#> 3 items flagged at Bayesian FDR 0.1 | 0 clean anchors
#> 
#>  item     d p_dif dif_mean dif_sd
#>   Q15 -0.16 0.973   -0.568  0.211
#>   Q10  1.29 0.884    0.429  0.241
#>   Q16  1.23 0.849    0.384  0.238
# true linking shift is -focal_mean = 0.5
c(estimate = dif$link[["c"]], mean_linking = dif$c_mean)
#>     estimate mean_linking 
#>    0.6155164    0.6099289 
```
