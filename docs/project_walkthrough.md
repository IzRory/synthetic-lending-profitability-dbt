# Project walkthrough

A reviewer can assess the project in about ten minutes.

1. Read the README disclaimer, dataset facts, architecture diagram, and calculation summary.
2. Open `scripts/generate_synthetic_data.py` and note its fixed seed, command-line arguments, exact output grains, and defect mode.
3. Compare a staging model with its source YAML to confirm explicit types and null cleanup.
4. Inspect `snap_branch_hierarchy` and `int_organization__month_end_hierarchy` for history and month-end as-of logic.
5. Follow revenue and cost components into `int_finance__loan_components` and the isolated profit calculation.
6. Review the incremental configuration and unique key in `fct_loan_profitability`.
7. Open the branch P&L and executive summary to see aggregation, reconciliation flags, and prior-month variances.
8. Read the eight singular tests and three unit-test fixtures.
9. Run the clean quick start, SQLFluff, documentation generation, and artifact checker.
10. Check the GitHub Actions run and release tag for remote evidence.

The normal build should finish with 25 models, 11 seeds, 1 snapshot, 11 sources, 243 data tests, and 3 unit tests. The final row counts are 25,000 loan facts, 1,440 branch-month P&L rows, and 216 executive-summary rows.

