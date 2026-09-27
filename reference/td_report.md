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
  file = NULL
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

## Value

The report as a character string (invisibly if written to file).

## Examples

``` r
sim <- td_simulate(n_ref = 600, n_focal = 150, n_items = 30, seed = 1)
dif <- td_dif(td_calibrate(sim$responses, sim$group))
#> Warning: Estimated DIF-free share is at the 0.5 identification bound: linking is weakly identified. Compare with the purified linking (c_purified = 0.678) and treat flags with caution.
rep <- td_report(dif, td_impact(dif, cut = 18, n_draws = 50, seed = 1),
                 td_features(dif, sim$features), c("English", "French"))
#> Warning: Dropped features with no variation across items: cultural
cat(rep)
#> # Score comparability: English vs French forms
#> 
#> ## Samples
#> - English: 600 examinees; French: 150 examinees.
#> 
#> ## Linking and anchors
#> - The French group's mean ability is estimated at -0.46 logits relative to the English group (SE 0.18).
#> - This estimate relies on a majority of items being free of DIF (estimated DIF-free share: 50.0%), not on DIF cancelling out. Linking with all items as anchors would have given -0.63.
#> - 0 items qualify as clean anchors (posterior DIF probability below 0.2).
#> - **Caution:** the DIF-free share is at its identification bound, so the linking is weakly identified. Purified linking gives -0.68; resolve the discrepancy with expert item review before relying on these results.
#> 
#> ## Item-level DIF
#> - 7 of 30 items are flagged (Bayesian false discovery rate 10.0%).
#> 
#> | item | DIF (logits) | posterior SD | P(DIF) | direction |
#> |---|---|---|---|---|
#> | Q21 | +0.81 | 0.16 | 1.00 | harder in French |
#> | Q04 | +0.52 | 0.20 | 0.96 | harder in French |
#> | Q18 | +0.46 | 0.22 | 0.92 | harder in French |
#> | Q14 | +0.46 | 0.20 | 0.94 | harder in French |
#> | Q19 | +0.43 | 0.21 | 0.91 | harder in French |
#> | Q03 | +0.40 | 0.23 | 0.86 | harder in French |
#> | Q12 | +0.28 | 0.21 | 0.75 | harder in French |
#> 
#> ## Aggregate impact
#> - Expected pass rate of the French group: 15.7% on the translated form vs 19.7% on a DIF-free form; change -4.1 points (90% interval -10.5 to -0.3).
#> - An examinee exactly at the cut is expected to score -1.12 raw points on the translated form (interval -2.51 to -0.11).
#> 
#> ## What predicts DIF (guidance for translators)
#> | feature | DIF per feature (logits) | SE | p |
#> |---|---|---|---|
#> | vocabulary | +0.52 | 0.15 | 0.000 |
#> | idiom | +0.46 | 0.13 | 0.001 |
#> | units | -0.53 | 0.27 | 0.048 |
#> 
#> Residual DIF SD not explained by features: 0.09 logits.
#> 
#> ## Notes for review
#> - Flagged items call for expert review of the translation before any statistical adjustment.
#> - Conclusions assume the Rasch model holds in both groups and that most items are DIF-free.
#> - Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).
# To save: td_report(dif, file = file.path(tempdir(), "comparability.md"))
```
