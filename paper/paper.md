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

<!-- DRAFT. Verify every reference and number before submission, and update
the validation section after the linking-estimator revision. Check the
journal's policy on disclosing AI-assisted software and writing. -->

# Summary

Certification boards and K-12 programs increasingly offer exams in more than
one language, and must show that scores mean the same thing across versions
[@standards2014; @itc2017]. `transDIF` provides an adaptation-comparability
workflow for small translated-language groups. It calibrates the Rasch model
in each group and models between-language difficulty differences with an
empirical-Bayes spike-and-slab mixture. The mixture performs linking, anchor
selection and DIF detection with local false discovery rates [@efron2004],
and it warns when the linking is weakly identified. The package then
quantifies whether item-level DIF adds up to different pass rates, explains
DIF by item features to guide translators, and drafts a comparability report.

# Statement of need

General DIF software [@magis2010] and the Mantel-Haenszel procedure
[@holland1988] assume adequate samples and anchors free of DIF. In adapted
tests, language groups are small and differ in ability, and translation
effects often run in one direction, so anchors are contaminated
[@kopf2015]. `transDIF` targets exactly this setting.

# Validation

<!-- Update these numbers after the linking-estimator revision. -->
Across 12
replications per size, empirical-Bayes detection had the highest power at
every focal-group size (67% at n = 200 vs 43% for Mantel-Haenszel), and
shrinkage more than halved the error of DIF estimates for DIF-free items.
Feature effects were recovered with 83-100% CI coverage. False discovery
rates exceeded the target at focal-group sizes of 100 or fewer.

# Acknowledgements

Software development and drafting were assisted by Claude (Anthropic). The author designed the methods, reviewed and validated all code and results, and takes full responsibility for the content.

# References
