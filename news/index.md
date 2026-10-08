# Changelog

## transDIF (development version)

- New
  [`td_sensitivity()`](https://edidatasolutions.github.io/transDIF/reference/td_sensitivity.md):
  how comparability conclusions depend on the linking assumption.
  Reports the ability difference, number of flagged items and pass-rate
  impact under mode, purified and all-item linking; a parametric
  bootstrap of the mode’s stability; the items whose DIF verdict depends
  on the linking; and an overall robust/sensitive verdict. Motivated by
  the First International Mathematics Study illustration, where
  pervasive DIF on a short test left the linking unidentified.
- [`td_report()`](https://edidatasolutions.github.io/transDIF/reference/td_report.md)
  gains a `sensitivity` argument that adds this analysis to the
  comparability report.
- [`td_dif()`](https://edidatasolutions.github.io/transDIF/reference/td_dif.md)
  gains `c_fixed` and `c_se_fixed` to fit the DIF model under an
  analyst-chosen linking.

## transDIF 0.1.0

CRAN release: 2026-10-08

- Initial release.
- Per-group Rasch calibration with relative standard errors
  ([`td_calibrate()`](https://edidatasolutions.github.io/transDIF/reference/td_calibrate.md)).
- Robust linking by the precision-weighted mode of item differences,
  with a sandwich SE and a warning when two item clusters are equally
  plausible, and small-sample DIF detection with an empirical-Bayes
  spike-and-slab model and local false discovery rates
  ([`td_dif()`](https://edidatasolutions.github.io/transDIF/reference/td_dif.md)),
  plus a Mantel-Haenszel baseline
  ([`td_mh()`](https://edidatasolutions.github.io/transDIF/reference/td_mh.md)).
- [`td_features()`](https://edidatasolutions.github.io/transDIF/reference/td_features.md)
  drops item features with no variation (with a warning) instead of
  failing.
- Aggregate pass-rate impact with linking and DIF uncertainty
  ([`td_impact()`](https://edidatasolutions.github.io/transDIF/reference/td_impact.md)).
- Item-feature meta-regression and a draft comparability report
  ([`td_features()`](https://edidatasolutions.github.io/transDIF/reference/td_features.md),
  [`td_report()`](https://edidatasolutions.github.io/transDIF/reference/td_report.md)).
