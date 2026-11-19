# R-versus-SQL validation

The project author reproduced the observed population-size summary from the original EPA CSV using DuckDB SQL through RStudio.

## Positive-population results

Programmatic comparisons matched the R export for all three size groups across flagged counts, unflagged counts, known-flag denominators, and rounded percentages.

| People served | Flagged | Known flags | Percentage |
|---|---:|---:|---:|
| 1–1,000 | 255 | 6,898 | 3.70% |
| 1,001–10,000 | 72 | 3,209 | 2.24% |
| More than 10,000 | 15 | 1,095 | 1.37% |

All four column comparisons returned TRUE, using a numeric tolerance of 1e-10.

## Reported-zero results

A separate SQL query returned 17 systems, 0 flagged systems, and 17 known flags. These totals matched the aggregated R export reported_zero_by_state.csv.

## Scope

This check covers observed counts and percentages. The regression estimates and confidence intervals were produced by analysis.R.

SQL results and comparison records are stored in sql_exports/.
