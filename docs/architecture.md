# Architecture

## Runtime

DuckDB is the required local and CI engine. The profile writes the database under `target/`, which Git ignores. Generated CSV seeds load into `analytics_raw`; dbt relations build in `analytics`.

## Transformation path

```text
generated CSV files
  -> staging views
  -> hierarchy snapshot and finance components
  -> enriched loan components
  -> incremental loan profitability fact
  -> monthly branch P&L
  -> region and company executive summary
```

Staging models keep source grains and limit their work to casting, blank-to-null handling, and category normalization. Intermediate models isolate joins and calculations so tests can target one responsibility. Dimensions materialize as tables. `fct_loan_profitability` uses an incremental `delete+insert` strategy keyed by `loan_id`; both aggregate marts materialize as tables.

## Effective-dated hierarchy

`snap_branch_hierarchy` preserves detected versions of each branch and business-effective start date. The month-end organization model reads current snapshot versions, joins each observed branch-month to the business-effective interval, and ranks matches by latest effective start. A singular test requires exactly one assignment for every loan.

## Control placement

Generic tests protect source and model keys near ingestion. Finance singular tests compare modeled values with control statements after component aggregation. Native unit tests run before their target SQL model materializes, which isolates calculation behavior from the 25,000-row fixture. The executive exposure depends on both final aggregate marts.

## Artifact evidence

`dbt docs generate` writes the manifest and catalog. `scripts/check_dbt_artifacts.py` checks required resources, test presence, result statuses, final descriptions, and sanitization. `scripts/generate_portfolio_assets.py` reads the manifest for the lineage image and queries DuckDB for the sample branch P&L image.

