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

For each state or system-size group, the percentage is the number of systems flagged for a health-based violation divided by the number of eligible systems with a known flag, multiplied by 100. For example, 5 flagged systems out of 100 with known flags would be reported as **5%**. The dashboard will show missing flags separately and leave the percentage blank when no flags are known.

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

In our case, the download date is 11/17/2026

### Reported health-based violations by system size

![Observed and state-adjusted percentages of water systems flagged for a health-based violation, by population served. Both percentages were lower in larger size groups. Error bars show 95% confidence intervals for the adjusted estimates.](figures/violation-percentages-by-size.png)

*Among systems that reported serving at least one person, the percentage flagged for a health-based violation was lower in each successively larger size group. The pattern held after accounting for differences across states. Open circles show observed percentages. Filled circles show state-adjusted estimates, and error bars show their 95% confidence intervals.*

**Systems reporting zero people served.** Of the 17 systems in this group, none were flagged for a health-based violation (0 of 17, 0%).

### Power BI dashboard

![Power BI report showing violation percentages by system size, state-adjusted estimates with 95% confidence intervals, and a state-by-size matrix](figures/power-bi-dashboard.png)

*The screenshot shows the all-eight-state view. The observed percentage was 3.05% (342 of 11,202 systems with a positive reported population and a known flag). In the Power BI report, the state slicer filters the observed results, and the adjusted chart shows estimates for all eight states.*

**Systems reporting zero people served.** Across all eight states, 0 of 17 systems in this group were flagged.

## Methods and limitations

### Observed percentages

The analysis includes active community water systems in Illinois, Indiana, Michigan, Minnesota, New York, Ohio, Pennsylvania, and Wisconsin. Each system contributes once. The observed percentage is the number flagged Yes for a reported health-based violation divided by the number with a Yes or No flag, multiplied by 100.

The size analysis includes 11,202 systems with a positive reported population. Project-defined size groups are 1–1,000, 1,001–10,000, and more than 10,000 people served.

### State adjustment and confidence intervals

We fitted a logistic regression with violation flag as the outcome and size group and state as categorical predictors. The model allows baseline odds to differ across states and estimates a common size-group association across states.

Adjusted percentages use direct standardization. For each size group, we predicted probabilities using the states of all 11,202 systems, then averaged those probabilities. Each adjusted estimate therefore uses the same state mix, weighted by the number of eligible systems in each state.

The 95% confidence intervals were calculated using the delta method and the model coefficient covariance matrix, with limits transformed through the log-odds scale to stay between 0% and 100%. These are model-based intervals around each adjusted percentage, treating the state mix as fixed.

### Limitations

The results describe associations in a reporting snapshot. Reporting delays, incomplete records, and differences in reporting practices may affect comparisons. Adjustment accounts for state and size group, while other system characteristics may also influence violations.

Observed patterns varied across states, and the fitted model assumes a common size-group association. The largest group had only 15 flagged systems. Its direct comparison with the middle group was uncertain (adjusted OR 0.605, 95% CI 0.345–1.060).

The confidence intervals reflect uncertainty under the fitted model. Reporting errors, model misspecification, and variation in reporting practices require separate consideration.

### Systems reporting zero people served

## Reproduce the analysis

The script uses base R and requires no additional packages.

1. Download and extract this repository using Code → Download ZIP.
2. Download and extract `SDWA_SYSTEM_SEARCH.csv` from the EPA ECHO Drinking Water System Search dataset.
3. Open `analysis.R` in RStudio.
4. Choose Session → Set Working Directory → To Source File Location.
5. Click Source and select the EPA CSV when prompted.

The script regenerates the figure in `figures/` and these summary files in `power_bi_exports/`:

- `observed_by_state.csv` — state totals, including systems reporting zero population.
- `observed_by_size.csv` — the three positive population size groups.
- `observed_by_state_and_size.csv` — positive size groups within each state.
- `adjusted_by_size.csv` — state-adjusted percentages and 95% confidence limits.
- `reported_zero_by_state.csv` — reported-zero population results by state.

CSV percentages use a 0–100 scale. Blank percentages indicate a zero known-flag denominator. The published results used EPA data downloaded on November 17, 2026. Later releases may produce different results.

### Reported-zero population results

The published snapshot contained 17 systems reporting zero people served, with 0 flagged. These results are exported separately in `reported_zero_by_state.csv`. The positive-size summaries and regression use 11,202 systems with a positive reported population.

[Download EPA data](https://echo.epa.gov/tools/data-downloads#drinking-water-data-downloads)

[EPA data dictionary](https://echo.epa.gov/tools/data-downloads/sdwa-facility-search-download-summary) · [EPA reporting caveats](https://echo.epa.gov/help/sdwa-faqs)
