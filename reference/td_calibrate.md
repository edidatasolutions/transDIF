# Calibrate each language group separately

Fits the Rasch model by marginal maximum likelihood within each group,
each with its own mean-zero ability scale. The between-language
difference \`d = b_focal - b_ref\` therefore equals item DIF plus a
common shift \`c = -(focal mean ability on the reference scale)\`.
Separating the two is the linking problem \[td_dif()\] solves.

## Usage

``` r
td_calibrate(responses, group, ref = "ref", focal = "focal")
```

## Arguments

- responses:

  0/1 matrix (persons x items), column names = item ids.

- group:

  Group label per person.

- ref, focal:

  Labels of the reference (source-language) and focal (translated)
  groups.

## Value

An \`td_calibration\`: data frame \`items\` (\`item\`, \`b_ref\`,
\`se_ref\`, \`b_focal\`, \`se_focal\`, \`d\`, \`se_d\`) plus group
sizes, ability SDs and \`loc_var\` (variance of the two scales'
locations). \`se_ref\`/\`se_focal\` are absolute SEs; \`se_d\` uses
relative SEs, excluding the location uncertainty that is common to all
items (it belongs to the linking shift).

## Examples

``` r
sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
cal <- td_calibrate(sim$responses, sim$group)
head(cal$items)
#>   item      b_ref    se_ref   b_focal  se_focal         d      se_d
#> 1  Q01 -0.4011790 0.1014853 0.2963397 0.2030587 0.6975187 0.2019547
#> 2  Q02  1.4124002 0.1136520 1.7733131 0.2423619 0.3609129 0.2437344
#> 3  Q03  1.0146188 0.1072185 2.0444472 0.2576887 1.0298285 0.2553840
#> 4  Q04  0.7025781 0.1037696 1.8772952 0.2478715 1.1747171 0.2447616
#> 5  Q05  1.5944665 0.1174416 2.1036836 0.2614668 0.5092172 0.2630719
#> 6  Q06  0.5285284 0.1024068 0.6719639 0.2071595 0.1434355 0.2060573
```
