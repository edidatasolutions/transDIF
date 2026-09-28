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
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
td_features(dif, sim$features)
#>          term    estimate         se          z     p_value
#> 1 (Intercept) -0.05714491 0.08564583 -0.6672235 0.504629368
#> 2       idiom  0.21161373 0.19391980  1.0912435 0.275165749
#> 3    cultural  0.54969875 0.20130565  2.7306673 0.006320625
#> 4       units -0.46375958 0.14599001 -3.1766528 0.001489853
#> 5  vocabulary  0.25843348 0.13175854  1.9614172 0.049830371
```
