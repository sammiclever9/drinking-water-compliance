param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$RscriptPath = "Rscript"
)

$ErrorActionPreference = "Stop"

# Resolve the input path before changing directories.
$inputCsv = (Resolve-Path -LiteralPath $CsvPath).Path
$rscriptCommand = (Get-Command $RscriptPath -ErrorAction Stop).Source

# Run from the folder containing this runner.
Push-Location -LiteralPath $PSScriptRoot

try {
    # Regenerate the statistical analysis and R summaries.
    & $rscriptCommand --vanilla "analysis.R" $inputCsv

    if ($LASTEXITCODE -ne 0) {
        throw "analysis.R failed. The pipeline stopped."
    }

    # Generate SQL summaries, Parquet files, and validation records.
    & $rscriptCommand --vanilla "duckdb_analysis.R" $inputCsv

    if ($LASTEXITCODE -ne 0) {
        throw "duckdb_analysis.R failed. The pipeline stopped."
    }

    Write-Host "Local pipeline completed successfully."
}
finally {
    # Restore the original working directory.
    Pop-Location
}