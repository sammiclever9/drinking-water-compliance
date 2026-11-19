# Data source

- Provider: U.S. Environmental Protection Agency, ECHO.
- Dataset: Drinking Water System Search.
- Input file: SDWA_SYSTEM_SEARCH.csv.
- Download date: November 17, 2026.
- Input dimensions: 434,757 rows and 76 columns.
- MD5 fingerprint: 7f25843b6747c921d5b948babbfa7216.

Each row represents a public water system identified by PWSID. The analysis uses HEALTH_FLAG as the reported health-based violation indicator.

EPA defines health-based violations as violations of maximum contaminant levels, maximum residual disinfectant levels, or required treatment techniques. The download is refreshed weekly, while the underlying SDWIS data are updated quarterly.

The download date identifies when this file was obtained. EPA documents health-based violations under Latest Violation Status. That search uses unresolved violations from the latest compliance quarter or the last date the state reported activity, whichever is later. Based on the download field mapping and linked search documentation, we interpret HEALTH_FLAG as a latest reported compliance-status indicator.

The exact calendar quarter represented by the November 17, 2026 download has not been independently verified. EPA notes that SDWIS compliance data can lag by three to six months.

[Latest Violation Status definition](https://echo.epa.gov/help/facility-search/search-criteria-help)

## Reported-zero populations

The eligible population includes 17 systems reporting zero people served, with 0 flagged. Their results are exported in reported_zero_by_state.csv. The size-group analysis uses 11,202 systems with positive reported populations.

[Dataset documentation](https://echo.epa.gov/tools/data-downloads/sdwa-facility-search-download-summary)

[Violation definitions](https://echo.epa.gov/help/facility-search/drinking-water-search-results-help)
