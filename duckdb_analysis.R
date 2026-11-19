# Install the local database and its R interface.
# Run once in the console before using this script.
# install.packages(c("DBI", "duckdb"))

# Open an in-memory DuckDB database.
library(DBI)
con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")

# Select the source CSV and quote its path safely for SQL.
csv_path <- file.choose()
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
r_size_summary <- read.csv(file.choose(), stringsAsFactors = FALSE)

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
r_zero_summary <- read.csv(file.choose(), stringsAsFactors = FALSE)

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


# Create the SQL export folder.
sql_export_dir <- "sql_exports"
dir.create(sql_export_dir, showWarnings = FALSE)

# Export positive-size results.
write.csv(sql_size_summary,
          file.path(sql_export_dir, "observed_by_size_sql.csv"),
          row.names = FALSE, na = "")

# Export reported-zero totals separately.
write.csv(sql_zero_summary,
          file.path(sql_export_dir, "reported_zero_totals_sql.csv"),
          row.names = FALSE, na = "")

# Export comparison records.
write.csv(
  data.frame(column = names(size_checks), matches = unname(size_checks)),
  file.path(sql_export_dir, "r_vs_sql_size_checks.csv"),
  row.names = FALSE
)

write.csv(zero_comparison,
          file.path(sql_export_dir, "r_vs_sql_zero_checks.csv"),
          row.names = FALSE, na = "")

# Close the database connection.
dbDisconnect(con, shutdown = TRUE)
