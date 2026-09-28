# transDIF

**Does a score mean the same thing in both languages?**

A comparability workflow for translated and adapted exams, built for the
conditions where standard DIF tools break down: a small
translated-language group (50–200), a group that differs in ability, and
DIF that runs mostly in one direction, so anchors themselves are biased.

``` r

library(transDIF)

sim <- td_simulate(n_focal = 150, seed = 1)          # or your 0/1 matrix + group
cal <- td_calibrate(sim$responses, sim$group)        # Rasch MML per language group
dif <- td_dif(cal)                                   # robust linking + small-sample DIF
imp <- td_impact(dif, cut = 36)                      # does DIF change pass rates?
fea <- td_features(dif, sim$features)                # which features predict DIF?
cat(td_report(dif, imp, fea, c("English", "French")))
```

## Installation

From CRAN (once released):

``` r

install.packages("transDIF")
```

Development version from GitHub:

``` r

install.packages("pak")
pak::pak("edidatasolutions/transDIF")
```

## Method

- **Calibration.** Rasch MML in each group, with SEs from the exact
  marginal Hessian. DIF uses *relative* SEs: the scale-location
  uncertainty shared by all items belongs to the linking shift, and is
  added to its SE there.
- **Robust linking.** Item differences are modeled as
  `d_i ~ N(c + delta_i, se_i^2)`. The shift `c` (the ability difference)
  is the precision-weighted **mode** of the `d_i`: the center of the
  densest cluster of items. It assumes that DIF-free items form the
  largest cluster, not that DIF cancels out. Its SE is a sandwich
  estimate plus the scales’ location uncertainty.
- **Ambiguity warning.** If a second cluster of items is nearly as
  dense, the data cannot say which cluster is DIF-free. `td_dif` then
  warns, and the report shows both candidate shifts.
- **Small-sample DIF.** Given `c`, a spike-and-slab mixture (a DIF-free
  majority with negligible `tau0`, plus a directional DIF slab) gives
  each item a posterior DIF probability, a shrunken DIF estimate and a
  local-FDR flag.
- **Aggregate impact.** The group’s pass-rate change and the raw-score
  shift at the cut, from exact score distributions. Intervals propagate
  both linking and DIF uncertainty.
- **Feature explanation.** Random-effects meta-regression of DIF on item
  features, giving concrete guidance for translators.
- **Baselines** for comparison: mean linking, iterative purification,
  Mantel–Haenszel with purification and BH.

## Validation (known truth, 12 replications per size, `inst/validation/known_truth.R`)

60 items; reference n = 2,000; translated group 0.5 logits lower; ~35%
of items carry adaptation features that make them mostly harder in
translation.

**DIF detection** (items with DIF \> 0.2 logits, target FDR 10%):

| focal n | EB power / FDP | purified z power / FDP | Mantel–Haenszel power / FDP |
|---------|----------------|------------------------|-----------------------------|
| 50      | 10% / 19%      | 9% / 3%                | 4% / 8%                     |
| 100     | 21% / 12%      | 19% / 9%               | 17% / 4%                    |
| 200     | 63% / 9%       | 59% / 11%              | 43% / 12%                   |

EB has the most power at every size and meets the FDR target at n = 200.
At **n ≤ 100 its FDR runs above target** (12–19%), so at those sizes
treat flags as candidates for expert translation review, not
conclusions.

**DIF effect estimation** (RMSE, logits), EB shrinkage vs raw
differences: 0.26 vs 0.38 (n = 50), 0.20 vs 0.26 (n = 100), 0.16 vs 0.20
(n = 200). On DIF-free items the error falls by two-thirds or more
(e.g. 0.11 vs 0.38 at n = 50); genuinely large DIF is shrunk somewhat
toward the slab mean.

**Linking** (true shift 0.5):

| focal n | bias: mode / mean / purified | RMSE: mode / mean / purified |
|---------|------------------------------|------------------------------|
| 50      | 0.05 / 0.08 / 0.06           | 0.17 / 0.19 / 0.18           |
| 100     | 0.03 / 0.06 / 0.04           | 0.08 / 0.12 / 0.08           |
| 200     | -0.03 / 0.06 / -0.01         | 0.09 / 0.11 / 0.08           |

Mean linking is biased by directional DIF, and more data does not fix
that. The weighted mode beats it at every size and is roughly tied with
iterative purification here. In a broader benchmark (180 data sets:
balanced, directional and heavy DIF at n = 50/100/200;
`dev/bench_link.R`) it had the lowest overall RMSE of nine estimators
(0.114, vs 0.119 for purification, 0.137 for mean linking and 0.164 for
the joint mixture used in earlier development). Its 90% intervals cover
the true shift 94% of the time.

**Impact:** 90% intervals for the pass-rate change cover the truth in
92% of replications at n = 150 (true mean change -3.0 points, estimated
-1.9).

**Features:** idiom, cultural referent, units and vocabulary effects are
all recovered (true 0.60 / 0.50 / -0.40 / 0.35; mean estimates 0.62 /
0.52 / -0.42 / 0.29), with 95% CI coverage of 83–100%.

## Status

Done: `td_simulate`, `td_calibrate`, `td_dif`, `td_mh`, `td_impact`,
`td_features`, `td_report`. Next: a conservative FDR mode for focal
groups of 100 or fewer, uniform vs non-uniform DIF (2PL), polytomous
items, and validation on real French–English data.
