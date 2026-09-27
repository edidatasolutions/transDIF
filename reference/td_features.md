# Which item features predict DIF?

Random-effects meta-regression of each item's DIF estimate (\`d - c\`)
on item features (e.g. idioms, cultural referents, measurement units,
vocabulary load), weighting by \`1 / (se_d^2 + tau^2)\`. The
between-item variance \`tau^2\` not explained by the features is
estimated by the method of moments. Coefficients are logits of DIF per
unit of the feature. That is guidance a translation team can act on.

## Usage

``` r
td_features(dif, features)
```

## Arguments

- dif:

  An \`td_dif\`.

- features:

  Data frame with \`item\` and numeric feature columns.

## Value

Data frame of coefficients (\`term\`, \`estimate\`, \`se\`, \`z\`,
\`p_value\`) with attribute \`tau\` (residual DIF SD). Features with no
variation across items are dropped with a warning.

## Examples

``` r
sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
#> Warning: Estimated DIF-free share is at the 0.5 identification bound: linking is weakly identified. Compare with the purified linking (c_purified = 0.678) and treat flags with caution.
td_features(dif, sim$features)
#> Warning: Dropped features with no variation across items: cultural
#>          term    estimate         se         z      p_value
#> 1 (Intercept)  0.07199662 0.04790904  1.502777 0.1328964354
#> 2       idiom  0.46293011 0.13424269  3.448457 0.0005637999
#> 3       units -0.52785107 0.26708321 -1.976354 0.0481146561
#> 4  vocabulary  0.52380450 0.14733150  3.555278 0.0003775792
```
