# Fictional business rules

All calculations in this document are simplified portfolio examples for Summit Ridge Lending.

## Revenue

Base revenue equals funded amount multiplied by base margin basis points and divided by 10,000. Total revenue adds origination fee, partner statement revenue, and signed margin adjustments. Loans without a partner statement or margin adjustment receive a zero for that component.

## Direct cost

Direct cost combines commission, override, credit transaction, and signed true-up amounts. The generator creates one commission per loan and one or two credit transactions. Overrides and true-ups are optional, so their modeled default is zero.

## Operating cost allocation

The fixture contains one overhead amount per branch and month. The model divides that amount equally across funded loans in the same branch-month. `safe_divide` returns null for a zero count, and component-completeness tests prevent a null allocation from reaching the final fact.

## Profit and status

Profit is total revenue less total cost. Profit margin basis points equal profit divided by funded amount and multiplied by 10,000. The unrounded profit determines `PROFITABLE`, `BREAK_EVEN`, or `UNPROFITABLE`; presentation models then round currency to cents.

## Precision

Seeds use two-decimal currency values. Intermediate models avoid explicit rounding. Final facts and marts round currency and basis-point presentation fields. Reconciliation tolerances allow one cent where final rounding can introduce a difference.

## Organizational history

The applicable hierarchy record is the branch assignment whose business-effective interval contains the loan month end. Eight branches change regions midway through the generated 24-month window.

