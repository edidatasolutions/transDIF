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

## How much do the conclusions depend on the linking?

Linking assumes that DIF-free items form the largest cluster. When many
items show DIF, the data may not settle which items are DIF-free.
[`td_sensitivity()`](https://edidatasolutions.github.io/transDIF/reference/td_sensitivity.md)
shows the results under each linking assumption, how stable the mode is,
and which items’ DIF verdicts depend on the choice:

``` r

sens <- td_sensitivity(dif, cut = 24, B = 100, n_draws = 50, seed = 1)
sens
#> <td_sensitivity> verdict: SENSITIVE (tolerance 0.15 logits)
#> Linkings differ by up to 0.144 logits; 77% of 100 bootstrap modes fall within 0.15 of the estimate (90% interval 0.369 to 0.753)
#> 
#>  assumption shift focal_mean     se n_flagged pass_rate_change change_lower
#>        mode 0.479     -0.479 0.1163         9         -0.03579      -0.0646
#>    purified 0.519     -0.519 0.0964         8         -0.02903      -0.0491
#>   all_items 0.623     -0.623 0.0949         3         -0.00459      -0.0197
#>  change_upper
#>       -0.0188
#>       -0.0152
#>        0.0155
#> 
#> 6 linking-sensitive item(s):
#>  item     d flag_mode flag_purified flag_all_items linking_sensitive
#>   Q03 0.979      TRUE          TRUE          FALSE              TRUE
#>   Q15 1.126      TRUE          TRUE          FALSE              TRUE
#>   Q29 0.875      TRUE         FALSE          FALSE              TRUE
#>   Q30 1.039      TRUE          TRUE          FALSE              TRUE
#>   Q31 1.134      TRUE          TRUE          FALSE              TRUE
#>   Q36 1.044      TRUE          TRUE          FALSE              TRUE
```

The report has three parts:

- **Linkings.** The ability difference, the number of flagged items and
  the pass-rate impact under three assumptions: the densest cluster of
  items is DIF-free (mode), flagged items are removed until the rest
  agree (purification), and DIF cancels out over all items (mean).
- **Stability of the mode.** A parametric bootstrap redraws each item’s
  between-language difference and re-estimates the mode. The share of
  bootstrap modes within the tolerance (0.15 logits by default) of the
  estimate shows whether the densest cluster is clear or whether a
  slightly different sample would have picked another cluster.
- **Linking-sensitive items.** Items whose DIF flag changes from one
  linking to another.

The verdict is “robust” only when the linkings agree within the
tolerance *and* the mode is stable (at least 80% of bootstrap modes
within the tolerance). Here the linkings agree closely, but with 150
candidates the mode is not yet stable enough, so the verdict is
“sensitive”. Each part is available for reporting:

``` r

sens$linkings
#>   assumption     shift focal_mean         se n_flagged pass_rate_change
#> 1       mode 0.4791316 -0.4791316 0.11628014         9     -0.035792775
#> 2   purified 0.5186765 -0.5186765 0.09639721         8     -0.029034229
#> 3  all_items 0.6228016 -0.6228016 0.09491372         3     -0.004585517
#>   change_lower change_upper
#> 1  -0.06461305  -0.01880747
#> 2  -0.04909186  -0.01516744
#> 3  -0.01968962   0.01554250
sens$bootstrap
#>           sd        lower        upper share_within 
#>    0.1178181    0.3686549    0.7534359    0.7700000
sens$items[sens$items$linking_sensitive, ]
#>    item         d flag_mode flag_purified flag_all_items linking_sensitive
#> 3   Q03 0.9792888      TRUE          TRUE          FALSE              TRUE
#> 15  Q15 1.1255601      TRUE          TRUE          FALSE              TRUE
#> 29  Q29 0.8751295      TRUE         FALSE          FALSE              TRUE
#> 30  Q30 1.0387857      TRUE          TRUE          FALSE              TRUE
#> 31  Q31 1.1338645      TRUE          TRUE          FALSE              TRUE
#> 36  Q36 1.0436927      TRUE          TRUE          FALSE              TRUE
```

### Two contrasting cases

With a larger translated-language group, the same 40-item design gives a
clear answer: the linkings agree and the mode barely moves under
resampling.

``` r

big <- td_simulate(n_ref = 1000, n_focal = 400, n_items = 40, seed = 1)
dif_big <- td_dif(td_calibrate(big$responses, big$group))
td_sensitivity(dif_big, cut = 24, B = 100, n_draws = 50, seed = 1)
#> <td_sensitivity> verdict: ROBUST (tolerance 0.15 logits)
#> Linkings differ by up to 0.059 logits; 98% of 100 bootstrap modes fall within 0.15 of the estimate (90% interval 0.307 to 0.521)
#> 
#>  assumption shift focal_mean     se n_flagged pass_rate_change change_lower
#>        mode 0.400     -0.400 0.0829         8         -0.02215      -0.0487
#>    purified 0.400     -0.400 0.0692         8         -0.02202      -0.0455
#>   all_items 0.459     -0.459 0.0682         9         -0.00727      -0.0238
#>  change_upper
#>       0.00168
#>      -0.00130
#>       0.02257
#> 
#> 3 linking-sensitive item(s):
#>  item     d flag_mode flag_purified flag_all_items linking_sensitive
#>   Q01 0.723      TRUE          TRUE          FALSE              TRUE
#>   Q25 0.108     FALSE         FALSE           TRUE              TRUE
#>   Q29 0.151     FALSE         FALSE           TRUE              TRUE
```

Even a robust verdict can list a few linking-sensitive items: they sit
near the flagging boundary, so a small shift in the linking moves them
across it. They deserve review, but the overall conclusion does not
depend on them.

A short test with pervasive DIF and a small group is the opposite case.
No cluster of DIF-free items dominates, the linkings disagree, and the
mode jumps between clusters under resampling:

``` r

heavy <- c(idiom = 0.18, cultural = 0.18, units = 0.10, vocabulary = 0.2)
short <- td_simulate(n_ref = 1000, n_focal = 80, n_items = 16,
                     feature_prev = heavy, seed = 5)
dif_short <- suppressWarnings(td_dif(td_calibrate(short$responses, short$group)))
td_sensitivity(dif_short, cut = 10, B = 100, n_draws = 50, seed = 1)
#> <td_sensitivity> verdict: SENSITIVE (tolerance 0.15 logits)
#> Linkings differ by up to 0.201 logits; 50% of 100 bootstrap modes fall within 0.15 of the estimate (90% interval 0.335 to 0.939)
#> 
#>  assumption shift focal_mean    se n_flagged pass_rate_change change_lower
#>        mode 0.796     -0.796 0.146         4          0.03610      0.02252
#>    purified 0.683     -0.683 0.143         1          0.02410      0.00119
#>   all_items 0.595     -0.595 0.140         0          0.00105     -0.03013
#>  change_upper
#>        0.0526
#>        0.0373
#>        0.0202
#> 
#> 4 linking-sensitive item(s):
#>  item       d flag_mode flag_purified flag_all_items linking_sensitive
#>   Q01  0.2610      TRUE         FALSE          FALSE              TRUE
#>   Q06  0.0914      TRUE         FALSE          FALSE              TRUE
#>   Q10  0.2123      TRUE         FALSE          FALSE              TRUE
#>   Q13 -0.0958      TRUE          TRUE          FALSE              TRUE
```

Here the conclusion itself changes with the assumption: the estimated
effect of DIF on the pass rate is +3.6 points under the mode, +2.4 under
purification and essentially zero under mean linking, whose interval
includes zero.

### Reading the verdict

A “sensitive” verdict does not say which linking is right, and it does
not mean the mode is wrong. It says that a conclusion depends on an
assumption the data cannot check. In the package’s simulations,
“sensitive” verdicts were concentrated in the hardest designs (short
tests, small groups, pervasive DIF), where linking errors are larger for
every method; within a given design, the verdict did not tell more
accurate estimates from less accurate ones. In practice:

1.  When the verdict is robust, report the mode-based results.
2.  When it is sensitive, report the results under all three linkings,
    say which conclusions change, and do not present a single pass-rate
    impact as settled.
3.  In either case, send the linking-sensitive items to content and
    translation experts. Only their review can settle which items should
    anchor the scale.

The report can be included in the comparability report with
`td_report(dif, ..., sensitivity = sens)`.

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
#> - Conclusions assume the Rasch model holds in both groups and that DIF-free items form the largest cluster of items; td_sensitivity() shows how much they depend on that assumption.
#> - Frame decisions using the fairness chapter of the Standards (AERA, APA, NCME, 2014) and the ITC Guidelines for Translating and Adapting Tests (2nd ed., 2017).
```

With very small translated-language groups (around 50 candidates), every
method has little power to detect DIF, so treat flags as candidates for
expert review rather than conclusions.
