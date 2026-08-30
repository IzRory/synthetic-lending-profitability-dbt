$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$failureRoot = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot "target\failure_demo"))
$expectedPrefix = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot "target")) + [System.IO.Path]::DirectorySeparatorChar

if (-not $failureRoot.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to use a failure-demo path outside the repository target directory."
}

if (Test-Path -LiteralPath $failureRoot) {
    Remove-Item -LiteralPath $failureRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $failureRoot | Out-Null

foreach ($directory in @("models", "macros", "snapshots", "tests", "analyses", "profiles")) {
    Copy-Item -LiteralPath (Join-Path $repositoryRoot $directory) -Destination $failureRoot -Recurse
}
foreach ($file in @("dbt_project.yml", "packages.yml")) {
    Copy-Item -LiteralPath (Join-Path $repositoryRoot $file) -Destination $failureRoot
}

$python = Join-Path $repositoryRoot ".venv\Scripts\python.exe"
$dbt = Join-Path $repositoryRoot ".venv\Scripts\dbt.exe"
& $python (Join-Path $repositoryRoot "scripts\generate_synthetic_data.py") `
    --output-dir (Join-Path $failureRoot "seeds\generated") `
    --inject-failures

Push-Location $failureRoot
try {
    $env:DBT_PROFILES_DIR = "profiles"
    & $dbt seed --target ci --full-refresh | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failure-demo seed step did not complete." }
    & $dbt run --target ci --select "path:models/staging" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failure-demo staging step did not complete." }
    & $dbt snapshot --target ci | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failure-demo snapshot step did not complete." }
    & $dbt run --target ci --full-refresh | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failure-demo model step did not complete." }
    $logPath = Join-Path $failureRoot "failure-demo.log"
    & $dbt test --target ci --select `
        source_unique_raw_lending_loans_loan_id `
        assert_funding_amount_reconciles `
        assert_no_orphan_dimension_keys 2>&1 | Tee-Object -FilePath $logPath
    $testExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($testExitCode -eq 0) {
    throw "The defect fixture did not produce the expected test failures."
}

$logText = Get-Content -LiteralPath $logPath -Raw
foreach ($expectedTest in @(
    "source_unique_raw_lending_loans_loan_id",
    "assert_funding_amount_reconciles",
    "assert_no_orphan_dimension_keys"
)) {
    if (-not $logText.Contains($expectedTest)) {
        throw "Expected failure was not observed: $expectedTest"
    }
}

Write-Host "Expected failures observed for the duplicate loan, bad funding total, and orphaned program."
Write-Host "The clean generated seeds were not modified. Evidence: $logPath"
