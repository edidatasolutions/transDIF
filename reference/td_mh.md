# Mantel-Haenszel DIF with purification (conventional baseline)

Mantel-Haenszel DIF with purification (conventional baseline)

## Usage

``` r
td_mh(responses, group, ref = "ref", focal = "focal", fdr = 0.1, purify = TRUE)
```

## Arguments

- responses:

  0/1 matrix.

- group:

  Group label per person.

- ref, focal:

  Group labels.

- fdr:

  Benjamini-Hochberg level for flagging.

- purify:

  Re-run once matching on the total over non-flagged items.

## Value

Data frame: \`item\`, \`alpha_mh\`, \`delta_mh\` (ETS delta scale),
\`p_value\`, \`flag\`.

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
mh <- td_mh(sim$responses, sim$group)
table(flagged = mh$flag, true_dif = sim$truth$dif_item)
#>        true_dif
#> flagged FALSE TRUE
#>   FALSE     8   10
#>   TRUE      0    2
```
