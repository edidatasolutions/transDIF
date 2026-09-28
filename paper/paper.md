---
title: 'transDIF: Score comparability for translated and adapted exams'
tags:
  - R
  - psychometrics
  - differential item functioning
  - test adaptation
  - linking
authors:
  - name: Daniel Edi
    orcid: 0000-0001-5475-819X
    affiliation: 1
affiliations:
  - name: Independent Researcher
    index: 1
date: 27 September 2026
bibliography: paper.bib
---

<!-- DRAFT. Verify every reference and number before submission. Check the
journal's policy on disclosing AI-assisted software and writing. -->

# Summary

Certification boards and K-12 programs increasingly offer exams in more than
one language, and must show that scores mean the same thing across versions
[@standards2014; @itc2017]. `transDIF` provides an adaptation-comparability
workflow for small translated-language groups. It calibrates the Rasch model
in each group and links the groups through the precision-weighted mode of
the between-language difficulty differences: the densest cluster of items,
rather than the mean of all items, which assumes DIF cancels out. It warns
when two clusters are equally plausible. DIF is then detected with an
empirical-Bayes spike-and-slab model and local false discovery rates
[@efron2004]. The package then
quantifies whether item-level DIF adds up to different pass rates, explains
DIF by item features to guide translators, and drafts a comparability report.

# Statement of need

General DIF software [@magis2010] and the Mantel-Haenszel procedure
[@holland1988] assume adequate samples and anchors free of DIF. In adapted
tests, language groups are small and differ in ability, and translation
effects often run in one direction, so anchors are contaminated
[@kopf2015]. `transDIF` targets exactly this setting.

# Validation

Across 12 known-truth replications per focal-group size, mode linking beat
linking on all items at every size (RMSE 0.17, 0.08 and 0.09 at n = 50, 100
and 200), with 94% coverage of its 90% intervals. Across 180 data sets with
balanced, directional and heavy DIF it had the lowest error of nine linking
estimators. Empirical-Bayes detection had the highest power at every size
(63% at n = 200 vs 43% for Mantel-Haenszel) and met its 10% FDR target at
n = 200, though not at 100 or fewer. Shrinkage cut the error of DIF-free
item estimates by two-thirds, 90% intervals for the pass-rate impact covered
the truth 92% of the time, and item-feature effects were recovered with
83-100% CI coverage.

# Acknowledgements

Software development and drafting were assisted by Claude (Anthropic). The author designed the methods, reviewed and validated all code and results, and takes full responsibility for the content.

# References
