# R-versus-SQL validation

The project author reproduced the observed population-size and state-by-size summaries from the original EPA CSV using DuckDB SQL through RStudio.

## Positive-population results

Programmatic comparisons matched the R export for all three size groups across flagged counts, unflagged counts, known-flag denominators, and rounded percentages.

| People served | Flagged | Known flags | Percentage |
|---|---:|---:|---:|
| 1–1,000 | 255 | 6,898 | 3.70% |
| 1,001–10,000 | 72 | 3,209 | 2.24% |
| More than 10,000 | 15 | 1,095 | 1.37% |

All four column comparisons returned TRUE, using a numeric tolerance of 1e-10.

## State-by-size results

The project author also compared all 24 state-by-size rows with `power_bi_exports/observed_by_state_and_size.csv`, matching records on both state and size group. Both tables had unique keys and the same combinations.

All five column comparisons returned TRUE. Flagged counts, unflagged counts, missing counts, and known-flag denominators matched exactly. Rounded percentages matched within a numeric tolerance of 1e-10.

The SQL summary totals 342 flagged systems, 11,202 known flags, and 0 missing flags. These rows cover positive reported populations.

- [24-row SQL summary](../sql_exports/observed_by_state_and_size_sql.csv)
- [Five column checks](../sql_exports/r_vs_sql_state_size_checks.csv)

## Reported-zero results

A separate SQL query returned 17 systems, 0 flagged systems, and 17 known flags. These totals matched the aggregated R export reported_zero_by_state.csv.

## Scope

This check covers observed counts and percentages. The regression estimates and confidence intervals were produced by analysis.R.

SQL results and comparison records are stored in sql_exports/.
