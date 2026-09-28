# Draft a comparability report

Assembles a plain-language Markdown report of the linking, DIF,
aggregate impact and feature analyses, organized around the kinds of
evidence the Standards for Educational and Psychological Testing (2014;
fairness chapter) and the ITC Guidelines for Translating and Adapting
Tests (2nd ed., 2017) ask for. It is a draft for a psychometrician to
review, not a finished validity argument.

## Usage

``` r
td_report(
  dif,
  impact = NULL,
  features = NULL,
  languages = c("source", "target"),
  file = NULL,
  sensitivity = NULL
)
```

## Arguments

- dif:

  An \`td_dif\`.

- impact:

  Optional output of \[td_impact()\].

- features:

  Optional output of \[td_features()\].

- languages:

  Names of the source and target languages.

- file:

  Optional path to write the Markdown to.

- sensitivity:

  Optional output of \[td_sensitivity()\]; adds a section on how the
  conclusions depend on the linking assumption.

## Value

The report as a character string (invisibly if written to file).

## Examples

``` r
sim <- td_simulate(n_ref = 400, n_focal = 120, n_items = 20, seed = 5)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
rep <- td_report(dif, td_impact(dif, cut = 12, n_draws = 50, seed = 1),
                 td_features(dif, sim$features), c("English", "French"),
                 sensitivity = td_sensitivity(dif, B = 50, seed = 1))
cat(rep)
#> # Score comparability: English vs French forms
#> 
#> ## Samples
#> - English: 400 examinees; French: 120 examinees.
#> 
#> ## Linking and anchors
#> - The French group's mean ability is estimated at -0.62 logits relative to the English group (SE 0.25).
#> - This estimate relies on DIF-free items forming the largest cluster of items (estimated DIF-free share: 50.0%), not on DIF cancelling out. Linking with all items as anchors would have given -0.61.
#> - 0 items qualify as clean anchors (posterior DIF probability below 0.2).
#> 
#> ## Item-level DIF
#> - 3 of 20 items are flagged (Bayesian false discovery rate 10.0%).
#> 
#> | item | DIF (logits) | posterior SD | P(DIF) | direction |
#> |---|---|---|---|---|
#> | Q15 | -0.57 | 0.21 | 0.97 | easier in French |
#> | Q10 | +0.43 | 0.24 | 0.88 | harder in French |
#> | Q16 | +0.38 | 0.24 | 0.85 | harder in French |
#> 
#> ## Aggregate impact
#> - Expected pass rate of the French group: 22.7% on the translated form vs 22.7% on a DIF-free form; change +0.1 points (90% interval -7.9 to +7.3).
#> - An examinee exactly at the cut is expected to score +0.01 raw points on the translated form (interval -1.01 to +1.40).
#> 
#> ## Sensitivity to the linking assumption
#> - **Sensitive:** the conclusions depend on which items are assumed DIF-free. The linking assumptions differ by up to 0.01 logits, and only 64% of 50 bootstrap re-estimates of the mode fall within 0.15 logits of the estimate. Report the results under each assumption, and let expert item review decide which items anchor the scale.
#> 
#> | linking assumption | mean ability of the French group | items flagged |
#> |---|---|---|
#> | densest item cluster (mode) | -0.62 (SE 0.25) | 3 |
#> | iterative purification | -0.62 (SE 0.13) | 3 |
#> | all items as anchors | -0.61 (SE 0.12) | 3 |
#> 
#> - Items whose DIF verdict depends on the linking (review these first): Q14, Q16.
#> 
#> ## What predicts DIF (guidance for translators)
#> | feature | DIF per feature (logits) | SE | p |
#> |---|---|---|---|
#> | units | -0.46 | 0.15 | 0.001 |
#> | cultural | +0.55 | 0.20 | 0.006 |
#> | vocabulary | +0.26 | 0.13 | 0.050 |
#> | idiom | +0.21 | 0.19 | 0.275 |
#> 
#> Residual DIF SD not explained by features: 0.11 logits.
#> 
#> ## Notes for review
#> - Flagged items call for expert review of the translation before any statistical adjustment.
#> - Conclusions assume the Rasch model holds in both groups and that DIF-free items form the largest cluster of items; td_sensitivity() shows how much they depend on that assumption.
#> - Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).
# To save: td_report(dif, file = file.path(tempdir(), "comparability.md"))
```
