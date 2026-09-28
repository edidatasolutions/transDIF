# Sensitivity of the comparability conclusions to the linking assumption

Linking two language groups requires an assumption about which items are
free of DIF, and when DIF is pervasive on a short test the data may not
settle it. This function makes that dependence visible:

- Linking assumptions:

  The ability difference under the weighted mode (DIF-free items form
  the densest cluster), iterative purification, and all items as anchors
  (DIF cancels out), with the DIF model refitted under each and, if
  \`cut\` is given, the pass-rate impact under each.

- Stability of the mode:

  A parametric bootstrap redraws each item's between-language difference
  from its sampling distribution and re-estimates the mode. When
  DIF-free items form a clear cluster the bootstrap modes stay close to
  the estimate; when they do not, the mode jumps between clusters, which
  is exactly the failure a single estimate hides.

- Linking-sensitive items:

  Items whose DIF flag changes across the linking assumptions. These are
  the items to prioritize for review by content and translation experts.

The overall verdict is \`"robust"\` when the linkings agree within
\`tolerance\` logits and the bootstrap keeps at least \`stable_share\`
of the modes within \`tolerance\` of the estimate; otherwise
\`"sensitive"\`.

## Usage

``` r
td_sensitivity(
  dif,
  cut = NULL,
  tolerance = 0.15,
  stable_share = 0.8,
  B = 200,
  n_draws = 100,
  seed = NULL
)
```

## Arguments

- dif:

  A \`td_dif\` object (from \[td_dif()\]).

- cut:

  Optional raw-score passing standard for pass-rate impact.

- tolerance:

  Difference in the linking shift (logits) considered substantively
  negligible.

- stable_share:

  Minimum share of bootstrap modes within \`tolerance\` of the estimate
  for the mode to count as stable.

- B:

  Bootstrap replicates.

- n_draws:

  Posterior draws for each pass-rate impact.

- seed:

  Optional seed.

## Value

A \`td_sensitivity\` object: \`\$linkings\` (one row per assumption:
\`assumption\`, \`shift\`, \`focal_mean\`, \`se\`, \`n_flagged\`, and
pass-rate impact columns when \`cut\` is given), \`\$bootstrap\`
(\`sd\`, \`lower\`, \`upper\` (90 linking and a \`linking_sensitive\`
indicator), \`\$range\` (largest difference between linkings) and
\`\$verdict\`.

## Details

\*\*What the verdict means.\*\* It is a statement about \*dependence on
an untestable assumption\*, not an estimate of which linking is correct.
In the package's known-truth simulations, data sets judged "sensitive"
did not have larger linking errors for the mode than those judged
"robust". Disagreement between linkings arose mostly because mean and
purified linking are biased under heavy directional DIF. Bootstrap
instability was only weakly associated with error. Use the verdict to
decide when to report results under several assumptions and to send the
linking-sensitive items to content and translation experts; only that
review can settle which items should anchor the scale.

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
sens <- td_sensitivity(dif, cut = 12, B = 100, n_draws = 50, seed = 1)
sens
#> <td_sensitivity> verdict: SENSITIVE (tolerance 0.15 logits)
#> Linkings differ by up to 0.011 logits; 57% of 100 bootstrap modes fall within 0.15 of the estimate (90% interval 0.360 to 0.928)
#> 
#>  assumption shift focal_mean    se n_flagged pass_rate_change change_lower
#>        mode 0.616     -0.616 0.246         3         0.000737      -0.0793
#>    purified 0.621     -0.621 0.125         3         0.002383      -0.0632
#>   all_items 0.610     -0.610 0.123         3        -0.000853      -0.0385
#>  change_upper
#>        0.0732
#>        0.0261
#>        0.0455
#> 
#> 2 linking-sensitive item(s):
#>  item      d flag_mode flag_purified flag_all_items linking_sensitive
#>   Q14 0.0474     FALSE          TRUE          FALSE              TRUE
#>   Q16 1.2312      TRUE         FALSE           TRUE              TRUE
```
