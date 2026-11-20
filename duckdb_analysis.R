# Install the local database and its R interface.
# Run once in the console before using this script.
# install.packages(c("DBI", "duckdb"))

# Open an in-memory DuckDB database.
library(DBI)
con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")

# Select the source CSV and quote its path safely for SQL.
# Accept a command-line path or use the interactive picker.
args <- commandArgs(trailingOnly = TRUE)
csv_path <- if (length(args) > 0) args[1] else file.choose()
sql_path <- as.character(dbQuoteString(con, csv_path))

# Load all columns as text to preserve the original codes.
dbExecute(con, paste0(
  "CREATE OR REPLACE TABLE raw_water AS
   SELECT * FROM read_csv(", sql_path, ", header = true, all_varchar = true)"
))

# Check the imported row count.
dbGetQuery(con, "SELECT COUNT(*) AS total_rows FROM raw_water")

# Select active community systems and convert population to numbers.
dbExecute(con, "
  CREATE OR REPLACE VIEW eligible_water AS
  SELECT
    TRIM(PWSID) AS system_id,
    TRIM(STATE_CODE) AS state,
    TRIM(HEALTH_FLAG) AS health_flag,
    TRY_CAST(TRIM(POPULATION_SERVED_COUNT) AS DOUBLE) AS population
  FROM raw_water
  WHERE TRIM(STATE_CODE) IN ('IL','IN','MI','MN','NY','OH','PA','WI')
    AND TRIM(PWS_ACTIVITY_CODE) = 'A'
    AND TRIM(PWS_TYPE_CODE) = 'CWS'
")


# Group positive populations and count Yes and No flags.
sql_size_summary <- dbGetQuery(con, "
  WITH grouped AS (
    SELECT
      CASE
        WHEN population <= 1000 THEN '1-1,000'
        WHEN population <= 10000 THEN '1,001-10,000'
        ELSE 'More than 10,000'
      END AS size_group,
      health_flag
    FROM eligible_water
    WHERE population > 0
      AND isfinite(population)
      AND population = trunc(population)
  ),
  counts AS (
    SELECT
      size_group,
      SUM(CASE WHEN health_flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_yes,
      SUM(CASE WHEN health_flag = 'No' THEN 1 ELSE 0 END) AS flagged_no
    FROM grouped
    GROUP BY size_group
  )
  SELECT
    size_group,
    flagged_yes,
    flagged_no,
    flagged_yes + flagged_no AS known_flags,
    ROUND(100.0 * flagged_yes /
      NULLIF(flagged_yes + flagged_no, 0), 2) AS pct_flagged
  FROM counts
  ORDER BY CASE size_group
    WHEN '1-1,000' THEN 1
    WHEN '1,001-10,000' THEN 2
    ELSE 3
  END
")

sql_size_summary


# Count reported-zero systems separately from the size summary.
sql_zero_summary <- dbGetQuery(con, "
  SELECT
    COUNT(*) AS systems,
    SUM(CASE WHEN health_flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_yes,
    SUM(CASE WHEN health_flag IN ('Yes','No') THEN 1 ELSE 0 END) AS known_flags
  FROM eligible_water
  WHERE population = 0
")

sql_zero_summary

# Select the exported R summary for positive size groups.
# r_size_summary <- read.csv(file.choose(), stringsAsFactors = FALSE)

# Load the R positive-size summary.
r_size_summary <- read.csv(
  file.path("power_bi_exports", "observed_by_size.csv"),
  stringsAsFactors = FALSE
)


# Align the R rows with the SQL size-group order.
stopifnot(
  !anyDuplicated(r_size_summary$size_group),
  setequal(r_size_summary$size_group, sql_size_summary$size_group)
)

r_size_aligned <- r_size_summary[
  match(sql_size_summary$size_group, r_size_summary$size_group), ]

# Compare shared numeric columns, allowing tiny rounding differences.
compare_columns <- c("flagged_yes", "flagged_no", "known_flags", "pct_flagged")

size_checks <- vapply(compare_columns, function(column) {
  isTRUE(all.equal(
    as.numeric(sql_size_summary[[column]]),
    as.numeric(r_size_aligned[[column]]),
    tolerance = 1e-10
  ))
}, logical(1))

size_checks
stopifnot(all(size_checks))

# Load the separate reported-zero results by state.
# r_zero_summary <- read.csv(file.choose(), stringsAsFactors = FALSE)
# Load the separate R reported-zero summary.
r_zero_summary <- read.csv(
  file.path("power_bi_exports", "reported_zero_by_state.csv"),
  stringsAsFactors = FALSE
)

# Confirm the file contains the reported-zero category.
stopifnot(
  nrow(r_zero_summary) == 8,
  all(r_zero_summary$size_group == "Reported zero population")
)

# Aggregate state counts to match the SQL summary.
r_zero_totals <- c(
  systems = sum(r_zero_summary$flagged_yes +
                  r_zero_summary$flagged_no + r_zero_summary$missing),
  flagged_yes = sum(r_zero_summary$flagged_yes),
  known_flags = sum(r_zero_summary$known_flags)
)

sql_zero_totals <- c(
  systems = as.numeric(sql_zero_summary$systems),
  flagged_yes = as.numeric(sql_zero_summary$flagged_yes),
  known_flags = as.numeric(sql_zero_summary$known_flags)
)

zero_comparison <- data.frame(
  metric = names(r_zero_totals),
  R = unname(r_zero_totals),
  SQL = unname(sql_zero_totals),
  matches = unname(r_zero_totals == sql_zero_totals)
)

zero_comparison
stopifnot(all(zero_comparison$matches))

# Confirm both comparisons passed.
message("R and SQL summaries match, including the separate reported-zero totals.")

# Create a folder for SQL-generated outputs.
sql_export_dir <- "sql_exports"
dir.create(sql_export_dir, showWarnings = FALSE)

# Export the three positive population size groups.
write.csv(
  sql_size_summary,
  file.path(sql_export_dir, "observed_by_size_sql.csv"),
  row.names = FALSE, na = ""
)

# Export reported-zero totals separately.
write.csv(
  sql_zero_summary,
  file.path(sql_export_dir, "reported_zero_totals_sql.csv"),
  row.names = FALSE, na = ""
)

# Record the positive-size checks by column.
size_comparison_record <- data.frame(
  column = names(size_checks),
  matches = unname(size_checks)
)

write.csv(
  size_comparison_record,
  file.path(sql_export_dir, "r_vs_sql_size_checks.csv"),
  row.names = FALSE
)

# Record the separate reported-zero comparisons.
write.csv(
  zero_comparison,
  file.path(sql_export_dir, "r_vs_sql_zero_checks.csv"),
  row.names = FALSE
)

# Print the folder containing the four exports.
normalizePath(sql_export_dir, winslash = "/", mustWork = TRUE)

# Summarize positive population groups within each state.
sql_state_size_summary <- dbGetQuery(con, "
  WITH grouped AS (
    SELECT
      state,
      CASE
        WHEN population <= 1000 THEN '1-1,000'
        WHEN population <= 10000 THEN '1,001-10,000'
        ELSE 'More than 10,000'
      END AS size_group,
      health_flag
    FROM eligible_water
    WHERE population > 0
      AND isfinite(population)
      AND population = trunc(population)
  ),
  counts AS (
    SELECT
      state,
      size_group,
      SUM(CASE WHEN health_flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_yes,
      SUM(CASE WHEN health_flag = 'No' THEN 1 ELSE 0 END) AS flagged_no,
      SUM(CASE WHEN health_flag IS NULL OR health_flag = ''
          THEN 1 ELSE 0 END) AS missing
    FROM grouped
    GROUP BY state, size_group
  )
  SELECT
    state,
    size_group,
    flagged_yes,
    flagged_no,
    missing,
    flagged_yes + flagged_no AS known_flags,
    ROUND(100.0 * flagged_yes /
      NULLIF(flagged_yes + flagged_no, 0), 2) AS pct_flagged
  FROM counts
  ORDER BY state, CASE size_group
    WHEN '1-1,000' THEN 1
    WHEN '1,001-10,000' THEN 2
    ELSE 3
  END
")

sql_state_size_summary

# Check the state-by-size summary against the earlier totals.
c(
  rows = nrow(sql_state_size_summary),
  flagged = sum(sql_state_size_summary$flagged_yes),
  known_flags = sum(sql_state_size_summary$known_flags),
  missing = sum(sql_state_size_summary$missing)
)

# Load the R state-by-size summary.
r_state_size <- read.csv(
  file.path("power_bi_exports", "observed_by_state_and_size.csv"),
  stringsAsFactors = FALSE
)

# Build matching keys from state and size group.
sql_keys <- paste(
  sql_state_size_summary$state,
  sql_state_size_summary$size_group,
  sep = "|"
)
r_keys <- paste(r_state_size$state, r_state_size$size_group, sep = "|")

# Require unique keys and the same state-size combinations.
stopifnot(
  nrow(sql_state_size_summary) == 24,
  nrow(r_state_size) == 24,
  !anyDuplicated(sql_keys),
  !anyDuplicated(r_keys),
  setequal(sql_keys, r_keys)
)

# Put the R rows in the same order as the SQL rows.
r_state_size_aligned <- r_state_size[match(sql_keys, r_keys), ]

# Compare counts exactly and rounded percentages within tolerance.
count_columns <- c("flagged_yes", "flagged_no", "missing", "known_flags")

state_size_checks <- vapply(count_columns, function(column) {
  identical(
    as.numeric(sql_state_size_summary[[column]]),
    as.numeric(r_state_size_aligned[[column]])
  )
}, logical(1))

state_size_checks["pct_flagged"] <- isTRUE(all.equal(
  as.numeric(sql_state_size_summary$pct_flagged),
  as.numeric(r_state_size_aligned$pct_flagged),
  tolerance = 1e-10
))

state_size_checks
stopifnot(all(state_size_checks))

# Check the existing reported-zero totals separately.
zero_comparison
stopifnot(all(zero_comparison$matches))

message("All 24 state-by-size rows match the R summary.")

# Export positive population groups within each state.
write.csv(
  sql_state_size_summary,
  file.path(sql_export_dir, "observed_by_state_and_size_sql.csv"),
  row.names = FALSE, na = ""
)

# Record which state-by-size columns matched the R results.
state_size_check_record <- data.frame(
  column = names(state_size_checks),
  matches = unname(state_size_checks)
)

write.csv(
  state_size_check_record,
  file.path(sql_export_dir, "r_vs_sql_state_size_checks.csv"),
  row.names = FALSE
)

# Read the new exports back from disk.
saved_state_size <- read.csv(
  file.path(sql_export_dir, "observed_by_state_and_size_sql.csv")
)
saved_checks <- read.csv(
  file.path(sql_export_dir, "r_vs_sql_state_size_checks.csv")
)

# Confirm row counts, totals, and successful comparisons.
stopifnot(
  nrow(saved_state_size) == 24,
  sum(saved_state_size$flagged_yes) == 342,
  sum(saved_state_size$known_flags) == 11202,
  sum(saved_state_size$missing) == 0,
  nrow(saved_checks) == 5,
  all(saved_checks$matches)
)

message("State-by-size SQL exports verified.")

# Record the R interface and database engine versions.
dir.create("metadata", showWarnings = FALSE)

duckdb_environment <- data.frame(
  R = R.version.string,
  DBI = as.character(packageVersion("DBI")),
  duckdb_package = as.character(packageVersion("duckdb")),
  duckdb_engine = dbGetQuery(con, "SELECT version() AS version")$version
)

write.csv(
  duckdb_environment,
  "metadata/duckdb-environment.csv",
  row.names = FALSE
)

# Save session details for the DuckDB workflow.
writeLines(
  capture.output(sessionInfo()),
  "metadata/duckdb-session-info.txt"
)

# Create a folder for cleaned system-level data.
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# Save positive whole-number populations as compressed Parquet.
dbExecute(con, "
  COPY (
    SELECT * FROM eligible_water
    WHERE population > 0
      AND isfinite(population)
      AND population = trunc(population)
  )
  TO 'data/processed/positive_population.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD)
")

# Save reported-zero populations in their own Parquet file.
dbExecute(con, "
  COPY (
    SELECT * FROM eligible_water
    WHERE population = 0
  )
  TO 'data/processed/reported_zero_population.parquet'
  (FORMAT PARQUET, COMPRESSION ZSTD)
")

# Verify the two files can be read back.
parquet_counts <- dbGetQuery(con, "
  SELECT 'Positive population' AS population_group, COUNT(*) AS systems
  FROM read_parquet('data/processed/positive_population.parquet')
  UNION ALL
  SELECT 'Reported zero population', COUNT(*)
  FROM read_parquet('data/processed/reported_zero_population.parquet')
")

parquet_counts

# Count known and missing flags in the positive-population file.
parquet_positive <- dbGetQuery(con, "
  SELECT
    COUNT(*) AS systems,
    COUNT(*) FILTER (WHERE health_flag = 'Yes') AS flagged_yes,
    COUNT(*) FILTER (WHERE health_flag = 'No') AS flagged_no,
    COUNT(*) FILTER (WHERE health_flag IN ('Yes', 'No')) AS known_flags,
    COUNT(*) FILTER (
      WHERE health_flag IS NULL OR health_flag = ''
    ) AS missing
  FROM read_parquet('data/processed/positive_population.parquet')
")

parquet_positive

# Count flags separately for systems reporting zero people served.
parquet_zero <- dbGetQuery(con, "
  SELECT
    COUNT(*) AS systems,
    COUNT(*) FILTER (WHERE health_flag = 'Yes') AS flagged_yes,
    COUNT(*) FILTER (WHERE health_flag = 'No') AS flagged_no,
    COUNT(*) FILTER (WHERE health_flag IN ('Yes', 'No')) AS known_flags,
    COUNT(*) FILTER (
      WHERE health_flag IS NULL OR health_flag = ''
    ) AS missing
  FROM read_parquet('data/processed/reported_zero_population.parquet')
")

parquet_zero

# Reconcile positive-population counts with the SQL size summary.
stopifnot(
  parquet_positive$systems ==
    parquet_positive$known_flags + parquet_positive$missing,
  parquet_positive$flagged_yes == sum(sql_size_summary$flagged_yes),
  parquet_positive$flagged_no == sum(sql_size_summary$flagged_no),
  parquet_positive$known_flags == sum(sql_size_summary$known_flags),
  parquet_positive$missing == 0
)

# Reconcile reported-zero counts with their separate SQL summary.
stopifnot(
  parquet_zero$systems == sql_zero_summary$systems,
  parquet_zero$flagged_yes == sql_zero_summary$flagged_yes,
  parquet_zero$known_flags == sql_zero_summary$known_flags,
  parquet_zero$flagged_no == parquet_zero$known_flags - parquet_zero$flagged_yes,
  parquet_zero$missing == 0
)

message("Parquet violation counts match the separate SQL summaries.")

# Save positive-population Parquet validation counts.
write.csv(
  parquet_positive,
  file.path(sql_export_dir, "parquet_positive_validation.csv"),
  row.names = FALSE
)

# Save reported-zero Parquet validation counts separately.
write.csv(
  parquet_zero,
  file.path(sql_export_dir, "parquet_zero_validation.csv"),
  row.names = FALSE
)

# Read both validation files back.
saved_positive <- read.csv(
  file.path(sql_export_dir, "parquet_positive_validation.csv")
)
saved_zero <- read.csv(
  file.path(sql_export_dir, "parquet_zero_validation.csv")
)

# Confirm the saved counts match the checked Parquet results.
stopifnot(
  isTRUE(all.equal(saved_positive, parquet_positive,
                   check.attributes = FALSE)),
  isTRUE(all.equal(saved_zero, parquet_zero,
                   check.attributes = FALSE))
)

message("Parquet validation exports verified.")

# Compare every positive-population record in both directions.
positive_record_check <- dbGetQuery(con, "
  WITH expected AS (
    SELECT system_id, state, health_flag, population
    FROM eligible_water
    WHERE population > 0
      AND isfinite(population)
      AND population = trunc(population)
  ),
  saved AS (
    SELECT system_id, state, health_flag, population
    FROM read_parquet('data/processed/positive_population.parquet')
  )
  SELECT
    (SELECT COUNT(*) FROM (
      SELECT * FROM expected EXCEPT ALL SELECT * FROM saved
    )) AS missing_from_parquet,
    (SELECT COUNT(*) FROM (
      SELECT * FROM saved EXCEPT ALL SELECT * FROM expected
    )) AS extra_in_parquet
")

positive_record_check

# Compare every reported-zero record in both directions.
zero_record_check <- dbGetQuery(con, "
  WITH expected AS (
    SELECT system_id, state, health_flag, population
    FROM eligible_water
    WHERE population = 0
  ),
  saved AS (
    SELECT system_id, state, health_flag, population
    FROM read_parquet('data/processed/reported_zero_population.parquet')
  )
  SELECT
    (SELECT COUNT(*) FROM (
      SELECT * FROM expected EXCEPT ALL SELECT * FROM saved
    )) AS missing_from_parquet,
    (SELECT COUNT(*) FROM (
      SELECT * FROM saved EXCEPT ALL SELECT * FROM expected
    )) AS extra_in_parquet
")

zero_record_check

# Require zero missing or extra records in either population group.
stopifnot(
  all(positive_record_check == 0),
  all(zero_record_check == 0)
)

message("Both Parquet files match their source records exactly.")


# Export positive-population record checks.
write.csv(
  positive_record_check,
  file.path(sql_export_dir, "parquet_positive_record_checks.csv"),
  row.names = FALSE
)

# Export reported-zero record checks separately.
write.csv(
  zero_record_check,
  file.path(sql_export_dir, "parquet_zero_record_checks.csv"),
  row.names = FALSE
)

# Read back both record-check exports.
saved_positive_records <- read.csv(
  file.path(sql_export_dir, "parquet_positive_record_checks.csv")
)
saved_zero_records <- read.csv(
  file.path(sql_export_dir, "parquet_zero_record_checks.csv")
)

# Check that each file contains one row with two zero counts.
stopifnot(
  nrow(saved_positive_records) == 1,
  ncol(saved_positive_records) == 2,
  all(as.matrix(saved_positive_records) == 0),
  nrow(saved_zero_records) == 1,
  ncol(saved_zero_records) == 2,
  all(as.matrix(saved_zero_records) == 0)
)

message("Parquet record-check exports verified.")



# Close the database connection.
dbDisconnect(con, shutdown = TRUE)