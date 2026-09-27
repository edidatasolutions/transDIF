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
#> <td_dif> 40 items | linking shift c = 0.468 (SE 0.106); mean-linking c = 0.623
#> estimated DIF-free share 0.69; DIF component mean +0.51, SD 0.05
#> 10 items flagged at Bayesian FDR 0.1 | 24 clean anchors
#> 
#>  item     d p_dif dif_mean dif_sd
#>   Q25 1.221 0.996    0.524 0.0572
#>   Q13 1.192 0.996    0.524 0.0560
#>   Q09 1.167 0.995    0.521 0.0598
#>   Q30 1.039 0.969    0.500 0.0962
#>   Q15 1.126 0.951    0.494 0.1165
#>   Q31 1.134 0.927    0.482 0.1365
#>   Q03 0.979 0.935    0.480 0.1270
#>   Q36 1.044 0.825    0.428 0.1935
#>   Q29 0.875 0.765    0.392 0.2085
#>   Q05 0.887 0.649    0.336 0.2388
```

The linking shift (the ability difference) is identified by a DIF-free
majority of items, not by assuming DIF cancels out. Compare with linking
on all items:

``` r

c(true = -sim$truth$focal_mean, robust = dif$link[["c"]], all_items = dif$c_mean)
#>      true    robust all_items 
#> 0.5000000 0.4681590 0.6228016
```

## Does DIF change pass rates?

``` r

td_impact(dif, cut = 24, n_draws = 100, seed = 1)
#>               quantity    estimate       lower      upper
#> 1       pass_rate_fair  0.19803351  0.15582883  0.2473419
#> 2 pass_rate_translated  0.16016604  0.13306985  0.1822478
#> 3     pass_rate_change -0.03786747 -0.06827959 -0.0210953
#> 4   score_shift_at_cut -1.22072777 -1.99835140 -0.7624327
```

## What should translators look at?

``` r

td_features(dif, sim$features)
#>          term    estimate         se          z      p_value
#> 1 (Intercept)  0.03170555 0.03984978  0.7956267 4.262490e-01
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
#> - The French group's mean ability is estimated at -0.47 logits relative to the English group (SE 0.11).
#> - This estimate relies on a majority of items being free of DIF (estimated DIF-free share: 68.9%), not on DIF cancelling out. Linking with all items as anchors would have given -0.62.
#> - 24 items qualify as clean anchors (posterior DIF probability below 0.2).
#> 
#> ## Item-level DIF
#> - 10 of 40 items are flagged (Bayesian false discovery rate 10.0%).
#> 
#> | item | DIF (logits) | posterior SD | P(DIF) | direction |
#> |---|---|---|---|---|
#> | Q25 | +0.52 | 0.06 | 1.00 | harder in French |
#> | Q13 | +0.52 | 0.06 | 1.00 | harder in French |
#> | Q09 | +0.52 | 0.06 | 0.99 | harder in French |
#> | Q30 | +0.50 | 0.10 | 0.97 | harder in French |
#> | Q15 | +0.49 | 0.12 | 0.95 | harder in French |
#> | Q31 | +0.48 | 0.14 | 0.93 | harder in French |
#> | Q03 | +0.48 | 0.13 | 0.94 | harder in French |
#> | Q36 | +0.43 | 0.19 | 0.83 | harder in French |
#> | Q29 | +0.39 | 0.21 | 0.77 | harder in French |
#> | Q05 | +0.34 | 0.24 | 0.65 | harder in French |
#> 
#> ## Notes for review
#> - Flagged items call for expert review of the translation before any statistical adjustment.
#> - Conclusions assume the Rasch model holds in both groups and that most items are DIF-free.
#> - Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).
```

With focal groups of 100 or fewer, treat flags as candidates for expert
review: the package’s validation shows its false discovery rate can
exceed the target at those sizes.
