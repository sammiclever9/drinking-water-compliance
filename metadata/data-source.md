# Data source

- Provider: U.S. Environmental Protection Agency, ECHO.
- Dataset: Drinking Water System Search.
- Input file: SDWA_SYSTEM_SEARCH.csv.
- Download date: November 17, 2026.
- Input dimensions: 434,757 rows and 76 columns.
- MD5 fingerprint: 7f25843b6747c921d5b948babbfa7216.

Each row represents a public water system identified by PWSID. The analysis uses HEALTH_FLAG as the reported health-based violation indicator.

EPA defines health-based violations as violations of maximum contaminant levels, maximum residual disinfectant levels, or required treatment techniques. The download is refreshed weekly, while the underlying SDWIS data are updated quarterly.

The download date identifies when this file was obtained. The precise reporting window for HEALTH_FLAG has not yet been independently confirmed for this release.

## Reported-zero populations

The eligible population includes 17 systems reporting zero people served, with 0 flagged. Their results are exported in reported_zero_by_state.csv. The size-group analysis uses 11,202 systems with positive reported populations.

[Dataset documentation](https://echo.epa.gov/tools/data-downloads/sdwa-facility-search-download-summary)

[Violation definitions](https://echo.epa.gov/help/facility-search/drinking-water-search-results-help)
