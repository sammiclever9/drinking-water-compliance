# v1.1.0 preparation check

On November 20, 2026, the project author reported successfully testing a fresh download of the main branch in preparation for v1.1.0.

## Workflow checked

- Ran the R analysis to regenerate its summary CSVs.
- Ran duckdb_analysis.R with one prompt for the original EPA CSV.
- Loaded all three R comparison inputs from power_bi_exports/.
- Regenerated all six SQL exports and comparison records.
- Confirmed that the size-group and state-by-size comparisons passed.

## Positive-population results

The three size groups contain 342 flagged systems out of 11,202 known flags. The state-by-size summary has 24 rows. Its flagged counts, unflagged counts, missing counts, and known-flag denominators matched R exactly. Rounded percentages matched within a numeric tolerance of 1e-10.

## Reported-zero results

A separate SQL summary contains 17 systems, 0 flagged systems, and 17 known flags. All three comparisons with the aggregated R reported-zero export passed. These results are stored separately in reported_zero_totals_sql.csv and r_vs_sql_zero_checks.csv.

## Environment

See [DuckDB environment](duckdb-environment.csv) and [session information](duckdb-session-info.txt).

## Scope

This records a fresh-main-branch test performed by the project author and reported in the project collaboration. It is a preparation check for v1.1.0. The existing v1.0.0 Power BI reproduction check is documented [separately](release-validation-v1.0.0.md). The HEALTH_FLAG calendar-quarter limitation remains documented in [data provenance](data-source.md).
