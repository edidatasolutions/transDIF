# Robust linking, anchor selection and small-sample DIF in one model

The between-language difference of item \`i\` is modeled as \`d_i ~
N(c + delta_i, se_i^2)\`, with DIF effects from a spike-and-slab
mixture:

- DIF-free (share \`pi0\`): \`delta_i ~ N(0, tau0^2)\`, where \`tau0\`
  is small;

- DIF (share \`1 - pi0\`): \`delta_i ~ N(m1, tau1^2)\`, where \`m1\`
  allows the directional DIF typical of translation.

The common shift \`c\` is the ability difference that linking must
recover. It is identified by the spike, i.e. by the assumption that a
majority of items are DIF-free (\`pi0 \> 0.5\`), not by assuming DIF
cancels out as mean linking does. The spike's SD \`tau0\` is fixed at a
negligible-DIF scale rather than estimated. Left free, it can widen to
swallow moderate DIF, which destabilizes the linking shift. Remaining
parameters are estimated by marginal ML with several starts. Each item
gets a posterior DIF probability, a shrunken DIF estimate, and a local
false discovery rate.

## Usage

``` r
td_dif(calibration, fdr = 0.1, tau0 = 0.05, anchor_max = 0.2)
```

## Arguments

- calibration:

  An \`td_calibration\`.

- fdr:

  Target Bayesian false discovery rate for flagging.

- tau0:

  SD of DIF among "DIF-free" items: the scale of DIF considered
  negligible (logits).

- anchor_max:

  Items with posterior DIF probability below this are reported as
  anchors.

## Value

An \`td_dif\` object: \`\$items\` (\`item\`, \`d\`, \`se_d\`, \`p_dif\`,
\`lfdr\`, \`dif_mean\`, \`dif_sd\` (posterior mean/SD of DIF), \`flag\`,
\`anchor\`) and \`\$link\` (\`c\`, \`c_se\`, \`pi0\`, \`m1\`, \`tau0\`,
\`tau1\`), baseline linking constants \`c_mean\` (all items as anchors)
and \`c_purified\`, and \`weakly_identified\` (TRUE, with a warning,
when \`pi0\` sits at its 0.5 bound; in simulation such fits gave the
largest linking errors and false-discovery rates, so rely on
\`c_purified\` and expert review then).

## Examples

``` r
sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
#> Warning: Estimated DIF-free share is at the 0.5 identification bound: linking is weakly identified. Compare with the purified linking (c_purified = 0.678) and treat flags with caution.
dif
#> <td_dif> 30 items | linking shift c = 0.463 (SE 0.183); mean-linking c = 0.628
#> estimated DIF-free share 0.50; DIF component mean +0.34, SD 0.26
#> 7 items flagged at Bayesian FDR 0.1 | 0 clean anchors
#> WARNING: weakly identified (DIF-free share at the 0.5 bound); purified linking c = 0.678
#> 
#>  item     d p_dif dif_mean dif_sd
#>   Q21 1.568 1.000    0.813  0.164
#>   Q04 1.175 0.960    0.522  0.203
#>   Q18 1.106 0.916    0.459  0.220
#>   Q14 1.042 0.939    0.457  0.196
#>   Q19 1.022 0.906    0.426  0.210
#>   Q03 1.030 0.864    0.400  0.229
#>   Q12 0.839 0.747    0.277  0.207
# true linking shift is -focal_mean = 0.5
c(estimate = dif$link[["c"]], mean_linking = dif$c_mean)
#>     estimate mean_linking 
#>    0.4625694    0.6283738 
```
