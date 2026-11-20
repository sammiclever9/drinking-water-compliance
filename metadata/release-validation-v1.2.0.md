# v1.2.0 preparation check

On November 20, 2026, the project author reported successfully testing a fresh download of main in preparation for v1.2.0.

## Workflow checked

- Ran analysis.R and duckdb_analysis.R using the original EPA CSV.
- Generated 10 CSV files in sql_exports/ and two Parquet files in data/processed/.
- Passed the R-versus-SQL summary comparisons and the Parquet count and record-level checks.

## Positive-population results

The positive-population Parquet file contains 11,202 systems, including 342 flagged systems and 10,860 unflagged systems, with 0 missing flags. The state-by-size summary has 24 rows matching the R results.

Bidirectional EXCEPT ALL comparisons across system ID, state, health flag, and population returned 0 missing and 0 extra records relative to the cleaned source.

## Reported-zero results

The separate reported-zero Parquet file contains 17 systems, with 0 flagged, 17 unflagged, and 0 missing flags. Its separate record comparisons returned 0 missing and 0 extra records.

## Scope

This records the project author's reported fresh-main-branch preparation test. It precedes publication of v1.2.0. The exact calendar quarter represented by HEALTH_FLAG remains unverified.

[Parquet validation details](parquet-validation.md)

[Data provenance](data-source.md)
