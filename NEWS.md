# transDIF 0.1.0

* Initial release.
* Per-group Rasch calibration with relative standard errors (`td_calibrate()`).
* Robust linking by the precision-weighted mode of item differences, with a sandwich SE and a warning when two item clusters are equally plausible, and small-sample DIF detection with an empirical-Bayes spike-and-slab model and local false discovery rates (`td_dif()`), plus a Mantel-Haenszel baseline (`td_mh()`).
* `td_features()` drops item features with no variation (with a warning) instead of failing.
* Aggregate pass-rate impact with linking and DIF uncertainty (`td_impact()`).
* Item-feature meta-regression and a draft comparability report (`td_features()`, `td_report()`).
