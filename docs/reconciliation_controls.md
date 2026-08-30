# Reconciliation controls

| Control | Test | Passing condition |
| --- | --- | --- |
| Funding amount | `assert_funding_amount_reconciles` | Branch-month modeled and statement amounts differ by no more than $0.01 |
| Funded-loan count | `assert_funded_loan_count_reconciles` | Branch-month modeled and statement counts match |
| Profit equation | `assert_profit_equation_balances` | Rounded revenue less cost agrees with rounded profit within $0.01 |
| Partner statement | `assert_partner_statement_reconciles` | Partner-month loan counts match and revenue differs by no more than $0.01 |
| Component completeness | `assert_component_completeness` | Every final loan has each required revenue, direct-cost, and overhead field |
| Margin bounds | `assert_margin_within_expected_bounds` | Profit margin remains between -1,500 and 1,500 fictional basis points |
| Dimension keys | `assert_no_orphan_dimension_keys` | Branch, region, program, and non-null partner keys resolve |
| Hierarchy assignment | `assert_hierarchy_assignment_is_unique` | Each loan month end receives one branch hierarchy assignment |

Generic tests also cover uniqueness, non-null fields, relationships, accepted values, positive funded measures, valid month ends, and composite keys.

## Unit tests

`unit_profit_equation` supplies one deterministic component row and checks revenue, cost, profit, margin, and status. `unit_partner_revenue_assignment` checks statement assignment and a zero adjustment default. `unit_month_end_hierarchy_selection` checks the region before and after a fictional branch move.

## Failure fixture

Run the isolated demonstration from PowerShell:

```powershell
.\scripts\demonstrate_failures.ps1
```

The script copies the project into `target/failure_demo`, generates three defects, materializes the models, and selects the three expected failing tests. It succeeds as a demonstration only when dbt reports each failure. The default seed files remain clean.

