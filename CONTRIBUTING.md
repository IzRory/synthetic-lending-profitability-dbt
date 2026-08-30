# Contributing

Create a focused branch, describe each affected model's grain in the pull request, and run the local validation sequence before requesting review.

```powershell
.\.venv\Scripts\python.exe scripts\generate_synthetic_data.py
.\.venv\Scripts\python.exe scripts\validate_no_sensitive_terms.py
.\.venv\Scripts\sqlfluff.exe lint models analyses snapshots tests
$env:DBT_PROFILES_DIR = "profiles"
.\.venv\Scripts\dbt.exe seed --full-refresh
.\.venv\Scripts\dbt.exe build --fail-fast
.\.venv\Scripts\dbt.exe docs generate
.\.venv\Scripts\python.exe scripts\check_dbt_artifacts.py
```

Do not commit credentials, local databases, generated dbt artifacts, logs, or non-synthetic records.

