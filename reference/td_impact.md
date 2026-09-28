# Does item-level DIF add up to different pass rates?

Differential test functioning for the translated form. With difficulties
on the reference scale (\`b_ref\`) and DIF effects \`delta\`, the
translated form has difficulties \`b_ref + delta\`. For the
translated-language population (ability N(-c, sigma_focal^2) on the
reference scale) the function computes the pass rate at raw cut \`cut\`
on the translated form versus on a DIF-free form, using exact score
distributions. It also computes the expected raw-score shift for an
examinee exactly at the cut. Intervals propagate both the linking
uncertainty (the focal group's mean ability is \`-c\`) and the posterior
uncertainty of each item's DIF.

## Usage

``` r
td_impact(dif, cut, n_draws = 200, level = 0.9, seed = NULL)
```

## Arguments

- dif:

  An \`td_dif\`.

- cut:

  Raw-score passing standard.

- n_draws:

  Posterior draws.

- level:

  Interval level.

- seed:

  Optional seed.

## Value

A data frame with estimate and interval for \`pass_rate_fair\`,
\`pass_rate_translated\`, \`pass_rate_change\` and
\`score_shift_at_cut\`.

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
td_impact(dif, cut = 12, n_draws = 50, seed = 1)
#>               quantity     estimate       lower      upper
#> 1       pass_rate_fair 0.2267433549  0.11089795 0.35274110
#> 2 pass_rate_translated 0.2274804477  0.17208872 0.27368403
#> 3     pass_rate_change 0.0007370928 -0.07930847 0.07321356
#> 4   score_shift_at_cut 0.0129088588 -1.01415063 1.40106100
```
