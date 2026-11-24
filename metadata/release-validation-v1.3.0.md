# v1.3.0 preparation and repeatability check

On November 24, 2026, Codex executed the downloaded project pipeline twice on the author's Windows computer using the original EPA CSV and R 4.3.3.

## Windows download block

The downloaded run_pipeline.ps1 carried a Zone.Identifier stream. RemoteSigned blocked the unsigned downloaded file before R started. After reviewing the runner, Codex used Unblock-File on that specific file and ran Windows PowerShell with a process-level RemoteSigned policy.

## Execution results

Both runs exited successfully and printed `Local pipeline completed successfully.` Each run regenerated the R summaries, SQL exports, Parquet files, figure, and metadata. All summary comparisons and Parquet record checks passed.

The 15 CSVs across power_bi_exports/ and sql_exports/ had identical SHA-256 hashes across the two runs. The positive-population Parquet file also had an identical hash. The reported-zero Parquet binary hash differed across runs; both runs' bidirectional record comparisons confirmed exact agreement with the cleaned source, including duplicate counts. This check establishes logical record repeatability for both Parquet datasets.

## Positive-population results

- 11,202 systems with known flags.
- 342 flagged and 10,860 unflagged.
- 0 missing flags.
- All 24 state-by-size rows matched R.
- 0 missing and 0 extra Parquet records.

## Reported-zero results

- 17 systems with known flags.
- 0 flagged and 17 unflagged.
- 0 missing flags.
- Separate SQL comparisons passed.
- 0 missing and 0 extra Parquet records.

## Limitations

R emitted startup locale warnings during execution. Both processes completed and validation passed. Earlier outputs may remain if a later run fails. The precise calendar quarter represented by HEALTH_FLAG remains unverified.

This records two runs of the downloaded main-branch project before publication of v1.3.0.
