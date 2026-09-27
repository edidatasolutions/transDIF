# transDIF

**Does a score mean the same thing in both languages?**

A comparability workflow for translated and adapted exams, built for the
conditions where standard DIF tools break down: a small translated-language
group (50–200), a group that differs in ability, and DIF that runs mostly in
one direction, so anchors themselves are biased.

```r
library(transDIF)

sim <- td_simulate(n_focal = 150, seed = 1)          # or your 0/1 matrix + group
cal <- td_calibrate(sim$responses, sim$group)        # Rasch MML per language group
dif <- td_dif(cal)                                   # robust linking + DIF in one model
imp <- td_impact(dif, cut = 36)                      # does DIF change pass rates?
fea <- td_features(dif, sim$features)                # which features predict DIF?
cat(td_report(dif, imp, fea, c("English", "French")))
```

## Installation

From CRAN (once released):

```r
install.packages("transDIF")
```

Development version from GitHub:

```r
install.packages("pak")
pak::pak("edidatasolutions/transDIF")
```

## Method

- **Calibration.** Rasch MML in each group, with SEs from the exact marginal
  Hessian. DIF uses *relative* SEs: the scale-location uncertainty shared by
  all items belongs to the linking shift, and is added to its SE there.
- **One model for linking, anchors and DIF.** Item differences
  `d_i ~ N(c + delta_i, se_i^2)`, with DIF from a spike-and-slab mixture: a
  DIF-free majority (negligible `tau0`) plus a directional DIF slab. The shift
  `c` (the ability difference) is identified by the DIF-free majority, not by
  DIF cancelling out. Items get posterior DIF probabilities, shrunken DIF
  estimates and a local-FDR flag.
- **Weak-identification warning.** When the estimated DIF-free share sits at
  its 0.5 bound, the model cannot separate anchors from the DIF cluster.
  `td_dif` then warns, and the report says so and shows purified linking.
- **Aggregate impact.** The group's pass-rate change and the raw-score shift at
  the cut, from exact score distributions. Intervals propagate both linking
  and DIF uncertainty.
- **Feature explanation.** Random-effects meta-regression of DIF on item
  features, giving concrete guidance for translators.
- **Baselines** for comparison: mean linking, iterative purification,
  Mantel–Haenszel with purification and BH.

## Validation (known truth, 12 replications per size, `inst/validation/known_truth.R`)

60 items; reference n = 2,000; translated group 0.5 logits lower; ~35% of items
carry adaptation features that make them mostly harder in translation.

**DIF detection** (items with DIF > 0.2 logits, target FDR 10%):

| focal n | EB power / FDP | purified z power / FDP | Mantel–Haenszel power / FDP |
|---|---|---|---|
| 50 | 22% / 13% | 9% / 3% | 4% / 8% |
| 100 | 30% / 19% | 19% / 9% | 17% / 4% |
| 200 | 67% / 11% | 59% / 11% | 43% / 12% |

EB has the most power at every size, but its FDR control is **anti-conservative
at n ≤ 100** (13–19% realized vs 10% target). At those sizes, treat flags as
candidates for expert translation review, not conclusions.

**DIF effect estimation** (RMSE, logits): EB shrinkage vs raw differences:
0.28 vs 0.38 (n = 50), 0.22 vs 0.26 (n = 100), 0.16 vs 0.20 (n = 200). On
DIF-free items the error is cut by more than half; genuinely large DIF is
shrunk somewhat toward the slab mean.

**Linking** (true shift 0.5):

| focal n | bias: mixture / mean / purified | RMSE: mixture / mean / purified |
|---|---|---|
| 50 | 0.00 / 0.08 / 0.06 | 0.18 / 0.19 / 0.18 |
| 100 | 0.00 / 0.06 / 0.04 | 0.10 / 0.12 / 0.08 |
| 200 | -0.06 / 0.06 / -0.01 | 0.11 / 0.11 / 0.08 |

Mean linking is biased by directional DIF, and more data does not fix that.
The mixture is nearly unbiased at n = 50–100, but its RMSE is **not better
than iterative purification**. 17–33% of fits were weakly identified. The
current recommendation is to report both, which the report does whenever the
warning fires. Improving the linking estimator is the top open item.

**Impact:** 90% intervals for the pass-rate change cover the truth in 83% of
replications at n = 150 (mean width 5.5 points). They covered only 50% before
linking uncertainty was propagated.

**Features:** idiom, cultural referent, units and vocabulary effects are all
recovered (true 0.60 / 0.50 / -0.40 / 0.35; mean estimates 0.62 / 0.52 /
-0.42 / 0.29), with 95% CI coverage of 83–100%.

## Status

Done: `td_simulate`, `td_calibrate`, `td_dif`, `td_mh`, `td_impact`,
`td_features`, `td_report`. Next: a better-identified linking estimator
(e.g. a robust M-estimator or a prior on the DIF-free share), a conservative
FDR mode for small groups, uniform vs non-uniform DIF (2PL), polytomous items,
and validation on real French–English data.
