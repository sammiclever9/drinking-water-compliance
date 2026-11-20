# Parquet validation

The project author generated two ZSTD-compressed Parquet files from the eligible EPA systems using DuckDB. Each file contains system ID, state, health flag, and numeric population served.

## Positive-population results

positive_population.parquet contains 11,202 systems with positive whole-number populations.

Querying the saved file returned 342 flagged systems, 10,860 unflagged systems, 11,202 known flags, and 0 missing flags. Flagged, unflagged, and known-flag counts matched the SQL size summary.

[Positive-population validation counts](../sql_exports/parquet_positive_validation.csv)

## Reported-zero results

reported_zero_population.parquet contains 17 systems reporting zero people served.

Querying the saved file returned 0 flagged systems, 17 unflagged systems, 17 known flags, and 0 missing flags. The totals matched the separate SQL reported-zero summary.

[Reported-zero validation counts](../sql_exports/parquet_zero_validation.csv)

## Record-level validation

The project author compared each saved Parquet file with its corresponding cleaned source records across system ID, state, health flag, and population.

### Positive-population records

Bidirectional EXCEPT ALL comparisons returned 0 records missing from Parquet and 0 extra records in Parquet across 11,202 systems.

[Positive-population record checks](../sql_exports/parquet_positive_record_checks.csv)

### Reported-zero records

A separate comparison returned 0 records missing from Parquet and 0 extra records in Parquet across the 17 systems reporting zero people served.

[Reported-zero record checks](../sql_exports/parquet_zero_record_checks.csv)

EXCEPT ALL comparisons preserve duplicate counts. All four fields and their record multiplicities matched between each Parquet file and its cleaned source.

## Reproduction

Run duckdb_analysis.R from the repository root. The script generates both Parquet files in data/processed/, queries them, checks their counts, and exports the validation summaries to sql_exports/.

All checks passed in the project author's reported run.
