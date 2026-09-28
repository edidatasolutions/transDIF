# transDIF (development version)

* New `td_sensitivity()`: how comparability conclusions depend on the linking
  assumption. Reports the ability difference, number of flagged items and
  pass-rate impact under mode, purified and all-item linking; a parametric
  bootstrap of the mode's stability; the items whose DIF verdict depends on
  the linking; and an overall robust/sensitive verdict. Motivated by the
  First International Mathematics Study illustration, where pervasive DIF on
  a short test left the linking unidentified.
* `td_report()` gains a `sensitivity` argument that adds this analysis to the
  comparability report.
* `td_dif()` gains `c_fixed` and `c_se_fixed` to fit the DIF model under an
  analyst-chosen linking.

# transDIF 0.1.0

* Initial release.
* Per-group Rasch calibration with relative standard errors (`td_calibrate()`).
* Robust linking by the precision-weighted mode of item differences, with a sandwich SE and a warning when two item clusters are equally plausible, and small-sample DIF detection with an empirical-Bayes spike-and-slab model and local false discovery rates (`td_dif()`), plus a Mantel-Haenszel baseline (`td_mh()`).
* `td_features()` drops item features with no variation (with a warning) instead of failing.
* Aggregate pass-rate impact with linking and DIF uncertainty (`td_impact()`).
* Item-feature meta-regression and a draft comparability report (`td_features()`, `td_report()`).
