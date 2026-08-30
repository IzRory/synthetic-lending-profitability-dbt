# Data dictionary

## Generated inputs

| Input | Grain | Business key | Expected rows | Null policy |
| --- | --- | --- | ---: | --- |
| `raw_loans` | One synthetic funded loan | `loan_id` | 25,000 | `partner_id` may be null; required profitability inputs may not |
| `raw_branch_hierarchy` | One branch effective period | `branch_id`, `effective_start_date` | 68 | Open-ended `effective_end_date` is null |
| `raw_programs` | One program | `program_id` | 12 | Open-ended `effective_end_date` is null |
| `raw_funding_statements` | One branch and month end | `month_end_date`, `branch_id` | 1,440 | No null control fields |
| `raw_partner_statements` | One partner-loan statement | `statement_id` | 8,960 | No null statement fields |
| `raw_credit_transactions` | One credit transaction | `credit_transaction_id` | 39,966 | No null transaction fields |
| `raw_commissions` | One funded-loan commission | `commission_id` | 25,000 | No null commission fields |
| `raw_overrides` | One optional loan override | `override_id` | 5,415 | Table omits loans without overrides |
| `raw_trueups` | One optional loan and posting-month true-up | `trueup_id` | 3,255 | Table omits loans without true-ups; amount may be signed |
| `raw_margin_adjustments` | One optional loan margin adjustment | `margin_adjustment_id` | 3,147 | Table omits loans without adjustments; amount may be signed |
| `raw_branch_overhead` | One branch and month end | `month_end_date`, `branch_id` | 1,440 | No null overhead fields |

## Published models

| Model | Grain | Key | Verified rows |
| --- | --- | --- | ---: |
| `dim_branch` | One current synthetic branch | `branch_id` | 60 |
| `dim_program` | One synthetic program | `program_id` | 12 |
| `dim_partner` | One synthetic partner | `partner_id` | 5 |
| `fct_loan_profitability` | One synthetic funded loan | `loan_id` | 25,000 |
| `fct_monthly_branch_pnl` | One branch and month end | `branch_id`, `month_end_date` | 1,440 |
| `mart_profitability_executive_summary` | One region or company and month end | `region_id`, `month_end_date` | 216 |

The dbt model YAML files define every final-mart column, its meaning, and applicable tests. Run `dbt docs generate --target ci` to inspect those definitions alongside lineage.

