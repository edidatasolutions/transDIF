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
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
cal <- td_calibrate(sim$responses, sim$group)
head(cal$items)
#>   item      b_ref    se_ref    b_focal  se_focal         d      se_d
#> 1  Q01 -1.0665941 0.1310266 -0.5185054 0.2178879 0.5480887 0.2295424
#> 2  Q02  0.6905033 0.1254879  1.1702381 0.2357935 0.4797349 0.2420547
#> 3  Q03 -0.5279999 0.1241780  0.3094700 0.2154656 0.8374699 0.2237220
#> 4  Q04  0.5106732 0.1238554  1.5369165 0.2526025 1.0262433 0.2561443
#> 5  Q05 -0.6698039 0.1255101 -0.2390148 0.2147244 0.4307891 0.2239025
#> 6  Q06 -0.2651736 0.1225462  0.4696299 0.2174139 0.7348035 0.2245787
```
