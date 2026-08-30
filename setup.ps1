$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath ".venv")) {
    python -m venv .venv
}

& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
& .\.venv\Scripts\python.exe scripts\generate_synthetic_data.py
$env:DBT_PROFILES_DIR = "profiles"
& .\.venv\Scripts\dbt.exe deps
& .\.venv\Scripts\python.exe scripts\validate_no_sensitive_terms.py
& .\.venv\Scripts\sqlfluff.exe lint models analyses snapshots tests
& .\.venv\Scripts\dbt.exe debug --target ci
& .\.venv\Scripts\dbt.exe seed --target ci --full-refresh
& .\.venv\Scripts\dbt.exe build --target ci --fail-fast
& .\.venv\Scripts\dbt.exe docs generate --target ci
& .\.venv\Scripts\python.exe scripts\check_dbt_artifacts.py
