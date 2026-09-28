# Simulate a source-language and a translated administration with known DIF

Items carry binary adaptation features (idiom, cultural referent,
measurement units, high vocabulary load). In the translated form an
item's difficulty shifts by \`sum(feature_effects \* features)\` plus
small noise, so DIF is directional (translations mostly harder) and
unbalanced, which is the case where mean-based linking fails. The focal
(translated) group is small and lower-scoring on average.

## Usage

``` r
td_simulate(
  n_ref = 2000,
  n_focal = 150,
  n_items = 60,
  focal_mean = -0.5,
  focal_sd = 1,
  feature_prev = c(idiom = 0.1, cultural = 0.1, units = 0.08, vocabulary = 0.12),
  feature_effects = c(idiom = 0.6, cultural = 0.5, units = -0.4, vocabulary = 0.35),
  dif_noise = 0.1,
  seed = NULL
)
```

## Arguments

- n_ref, n_focal:

  Group sizes.

- n_items:

  Test length.

- focal_mean, focal_sd:

  Focal-group ability (reference is N(0, 1)).

- feature_prev:

  Prevalence of each feature.

- feature_effects:

  DIF (logits) contributed by each feature.

- dif_noise:

  SD of feature-unrelated DIF on flagged items.

- seed:

  Optional seed.

## Value

An \`td_sim\`: \`\$responses\` (0/1 matrix, persons x items),
\`\$group\` (\`"ref"\`/\`"focal"\`), \`\$features\` (item data frame),
\`\$truth\` (\`b_ref\`, \`dif\`, \`focal_mean\`, \`focal_sd\`).

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
table(dif_item = sim$truth$dif_item)
#> dif_item
#> FALSE  TRUE 
#>     8    12 
head(sim$features)
#>     item idiom cultural units vocabulary
#> Q01  Q01     0        0     0          0
#> Q02  Q02     0        0     0          0
#> Q03  Q03     1        0     0          0
#> Q04  Q04     0        0     0          1
#> Q05  Q05     0        0     1          1
#> Q06  Q06     0        0     0          1
```
