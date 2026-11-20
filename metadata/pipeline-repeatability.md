# Local pipeline repeatability

The project author ran run_pipeline.ps1 twice successfully. Each run executes analysis.R followed by duckdb_analysis.R in separate R processes.

The second run regenerated existing outputs successfully. Both runs ended with “Local pipeline completed successfully.”

## Positive-population results

- 342 flagged out of 11,202 systems.
- All R-versus-SQL comparisons passed.
- Parquet record checks found 0 missing and 0 extra records.

## Reported-zero results

- 0 flagged out of 17 systems.
- Separate SQL comparisons passed.
- Separate Parquet record checks found 0 missing and 0 extra records.

## Scope

This confirms repeatability with the original EPA input on the author's computer. The runner stops on an R failure. Earlier outputs may remain after a failed run.
