$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath ".venv")) {
    python -m venv .venv
}

& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
& .\.venv\Scripts\python.exe scripts\generate_synthetic_data.py
$env:DBT_PROFILES_DIR = "profiles"
& .\.venv\Scripts\dbt.exe deps
& .\.venv\Scripts\dbt.exe seed --full-refresh
& .\.venv\Scripts\dbt.exe build

