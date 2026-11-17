[drinking-water-compliance-readme.md](https://github.com/user-attachments/files/34958271/drinking-water-compliance-readme.md)
# drinking-water-compliance
# Drinking Water Compliance in the Great Lakes States

**How common are reported health-based drinking water violations, and does the percentage of systems with a violation vary by state or by the number of people they serve?**

This project will build an interactive Power BI dashboard that lets residents and regional program managers explore that question. For each comparison, readers will see both the percentage and the number of water systems behind it.

## Data and scope

The project uses the U.S. Environmental Protection Agency’s public Drinking Water System Search dataset. Each row represents one public water system, identified by its Public Water System ID (`PWSID`). The analysis focuses on active community water systems in Illinois, Indiana, Michigan, Minnesota, New York, Ohio, Pennsylvania, and Wisconsin. It covers these eight states in full, using state boundaries. System size is based on the number of people served.

[EPA ECHO data download](https://echo.epa.gov/tools/data-downloads#drinking-water-data-downloads) · [EPA data dictionary](https://echo.epa.gov/tools/data-downloads/sdwa-facility-search-download-summary)

## How the measure works

A health-based violation involves a drinking water standard for contaminants, disinfectants, or required treatment practices. The analysis will use EPA’s health-based violation indicator (`HEALTH_FLAG`) and document its coding and reporting window for the downloaded release before calculating results.

For each state or system-size group, the percentage is the number of systems flagged for a health-based violation divided by the number of eligible systems with a known flag, multiplied by 100. For example, 5 flagged systems out of 100 with known flags would be reported as **5% (5 of 100)**. The dashboard will show missing flags separately and leave the percentage blank when no flags are known.

Each system counts once, regardless of how many people it serves or how many violations it has. The measure describes the share of systems flagged. Small groups can show large percentage changes from just one additional flagged system. Reporting delays and incomplete records can affect comparisons, and the dashboard summarizes a reporting snapshot. For current local water quality information, contact your water system.

[EPA search results guide](https://echo.epa.gov/help/facility-search/drinking-water-search-results-help) · [EPA drinking water data FAQs](https://echo.epa.gov/help/sdwa-faqs)

## Work plan

| Milestone | Estimated effort | Deliverable |
| --- | --- | --- |
| Week 1 | 3–4 hours | Source note, data audit, and counts of eligible systems, flagged systems, and missing flags by state and system size |
| Week 2 | 4–5 hours | Reproducible R analysis comparing observed percentages with estimates from a logistic regression that accounts for state and system size together |
| Week 3 | 4–5 hours | Power BI dashboard with a headline finding, state and system-size filters, and the counts behind each percentage |

The regression will show whether patterns by system size persist after accounting for differences across states, and whether patterns by state persist after accounting for system size. These comparisons describe associations in the reported data. An AWS pipeline is a follow-on milestone once the local workflow is reproducible.

## Getting started

1. Create the repository and add this file as `README.md`.
2. Download the **Drinking Water System Search Dataset** from EPA ECHO, extract `SDWA_SYSTEM_SEARCH.csv`, and record the download date.
3. In RStudio, count the rows and unique system IDs, check for duplicate or missing IDs, and tabulate all `HEALTH_FLAG` values, including missing values. Record the results before filtering or recoding.

Keep the source ZIP and CSV local. Commit the audit script and source note so others can reproduce the analysis using the EPA download.
