# Comparability of translated exam forms

When an exam is offered in a second language, the question is whether a
score means the same thing in both. Standard DIF tools struggle when the
translated group is small, differs in ability, and many items shift in
the same direction. transDIF is built for that situation.

## Data

A source-language group of 2,000 and a translated-language group of 150
who are 0.5 logits lower on average. Items with idioms, cultural
referents, measurement units or heavy vocabulary tend to shift in
translation.

``` r

library(transDIF)
sim <- td_simulate(n_ref = 2000, n_focal = 150, n_items = 40, seed = 5)
colSums(sim$features[-1])
#>      idiom   cultural      units vocabulary 
#>          4          8          4          2
```

## Calibrate each group, then link and detect DIF together

``` r

cal <- td_calibrate(sim$responses, sim$group)
dif <- td_dif(cal)
dif
#> <td_dif> 40 items | linking shift c = 0.479 (SE 0.116, mode); mean-linking c = 0.623
#> estimated DIF-free share 0.70; DIF component mean +0.51, SD 0.05
#> 9 items flagged at Bayesian FDR 0.1 | 24 clean anchors
#> 
#>  item     d p_dif dif_mean dif_sd
#>   Q25 1.221 0.995    0.522 0.0591
#>   Q13 1.192 0.996    0.522 0.0578
#>   Q09 1.167 0.993    0.519 0.0623
#>   Q30 1.039 0.962    0.495 0.1036
#>   Q15 1.126 0.942    0.488 0.1239
#>   Q31 1.134 0.916    0.475 0.1443
#>   Q03 0.979 0.921    0.472 0.1371
#>   Q36 1.044 0.803    0.415 0.2016
#>   Q29 0.875 0.727    0.372 0.2182
```

The linking shift (the ability difference) is the center of the densest
cluster of items, not the mean of all items, so it does not assume that
DIF cancels out. Compare with linking on all items:

``` r

c(true = -sim$truth$focal_mean, robust = dif$link[["c"]], all_items = dif$c_mean)
#>      true    robust all_items 
#> 0.5000000 0.4791316 0.6228016
```

## Does DIF change pass rates?

``` r

td_impact(dif, cut = 24, n_draws = 100, seed = 1)
#>               quantity    estimate       lower       upper
#> 1       pass_rate_fair  0.19513094  0.14950118  0.24928711
#> 2 pass_rate_translated  0.15933817  0.12855365  0.18308398
#> 3     pass_rate_change -0.03579277 -0.06834324 -0.01838312
#> 4   score_shift_at_cut -1.16064342 -1.99479015 -0.64982880
```

## What should translators look at?

``` r

td_features(dif, sim$features)
#>          term    estimate         se          z      p_value
#> 1 (Intercept)  0.02073289 0.03984978  0.5202762 6.028711e-01
#> 2       idiom  0.48388035 0.10197468  4.7451028 2.084004e-06
#> 3    cultural  0.51599144 0.08421317  6.1272061 8.943560e-10
#> 4       units -0.28103451 0.11066300 -2.5395526 1.109944e-02
#> 5  vocabulary  0.01735354 0.16537924  0.1049318 9.164299e-01
```

## A report to start from

``` r

cat(td_report(dif, languages = c("English", "French")))
#> # Score comparability: English vs French forms
#> 
#> ## Samples
#> - English: 2000 examinees; French: 150 examinees.
#> 
#> ## Linking and anchors
#> - The French group's mean ability is estimated at -0.48 logits relative to the English group (SE 0.12).
#> - This estimate relies on DIF-free items forming the largest cluster of items (estimated DIF-free share: 70.3%), not on DIF cancelling out. Linking with all items as anchors would have given -0.62.
#> - 24 items qualify as clean anchors (posterior DIF probability below 0.2).
#> 
#> ## Item-level DIF
#> - 9 of 40 items are flagged (Bayesian false discovery rate 10.0%).
#> 
#> | item | DIF (logits) | posterior SD | P(DIF) | direction |
#> |---|---|---|---|---|
#> | Q25 | +0.52 | 0.06 | 1.00 | harder in French |
#> | Q13 | +0.52 | 0.06 | 1.00 | harder in French |
#> | Q09 | +0.52 | 0.06 | 0.99 | harder in French |
#> | Q30 | +0.50 | 0.10 | 0.96 | harder in French |
#> | Q15 | +0.49 | 0.12 | 0.94 | harder in French |
#> | Q31 | +0.47 | 0.14 | 0.92 | harder in French |
#> | Q03 | +0.47 | 0.14 | 0.92 | harder in French |
#> | Q36 | +0.42 | 0.20 | 0.80 | harder in French |
#> | Q29 | +0.37 | 0.22 | 0.73 | harder in French |
#> 
#> ## Notes for review
#> - Flagged items call for expert review of the translation before any statistical adjustment.
#> - Conclusions assume the Rasch model holds in both groups and that most items are DIF-free.
#> - Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).
```

With focal groups of 100 or fewer, treat flags as candidates for expert
review: in the package’s validation the false discovery rate exceeded
its target at those sizes.
