# v1.0.0 reproduction check

On November 19, 2026, the project author reported completing a fresh-download check of the published v1.0.0 release.

## Checks completed

- Downloaded and extracted the v1.0.0 source archive.
- Ran analysis.R in a fresh R session using the original EPA CSV.
- Received the message `Analysis checks passed.`
- Reconnected the Power BI report to the regenerated summary CSVs and verified the displayed results.

## Positive-population results

- 342 flagged systems out of 11,202 with known flags, displayed as 3.05%.
- State-adjusted percentages of 3.80%, 2.15%, and 1.31% across increasing size groups.

## Reported-zero population results

The separate summary contained 0 flagged systems out of 17 reporting zero people served. The overall state summary includes all 11,219 eligible systems.

## Scope

This check was performed by the project author and reported in the project collaboration. It verifies the reported reproduction outcome using the original input. The precise calendar quarter represented by HEALTH_FLAG remains unverified, as documented in [the data provenance note](data-source.md).

[Validated release](https://github.com/sammiclever9/drinking-water-compliance/releases/tag/v1.0.0)
