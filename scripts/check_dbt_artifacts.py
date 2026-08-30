"""Validate dbt artifacts and print reproducible project evidence."""

from __future__ import annotations

import json
from pathlib import Path

from validate_no_sensitive_terms import scan_repository


REQUIRED_MODELS = {
    "fct_loan_profitability",
    "fct_monthly_branch_pnl",
    "mart_profitability_executive_summary",
}
REQUIRED_DATA_TESTS = {
    "assert_funding_amount_reconciles",
    "assert_funded_loan_count_reconciles",
    "assert_profit_equation_balances",
    "assert_partner_statement_reconciles",
    "assert_component_completeness",
    "assert_margin_within_expected_bounds",
    "assert_no_orphan_dimension_keys",
    "assert_hierarchy_assignment_is_unique",
}
REQUIRED_UNIT_TESTS = {
    "unit_profit_equation",
    "unit_partner_revenue_assignment",
    "unit_month_end_hierarchy_selection",
}
SUCCESS_STATUSES = {"success", "pass", "warn", "no-op", "reused"}


def load_json(path: Path) -> dict[str, object]:
    if not path.exists():
        raise RuntimeError(f"Required artifact is missing: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    target = root / "target"
    manifest = load_json(target / "manifest.json")
    run_results = load_json(target / "run_results.json")
    nodes = manifest.get("nodes", {})
    sources = manifest.get("sources", {})
    unit_tests = manifest.get("unit_tests", {})
    failures: list[str] = []

    model_nodes = {
        node.get("name"): node
        for node in nodes.values()
        if node.get("resource_type") == "model"
    }
    missing_models = REQUIRED_MODELS - set(model_nodes)
    if missing_models:
        failures.append(f"missing required models: {sorted(missing_models)}")

    for model_name in sorted(REQUIRED_MODELS & set(model_nodes)):
        node = model_nodes[model_name]
        if not str(node.get("description", "")).strip():
            failures.append(f"final model lacks a description: {model_name}")
        columns = node.get("columns", {})
        undocumented = [name for name, column in columns.items() if not str(column.get("description", "")).strip()]
        if undocumented:
            failures.append(f"final model has undocumented columns: {model_name}: {sorted(undocumented)}")

    data_test_names = {
        node.get("name")
        for node in nodes.values()
        if node.get("resource_type") == "test"
    }
    missing_data_tests = REQUIRED_DATA_TESTS - data_test_names
    if missing_data_tests:
        failures.append(f"missing required data tests: {sorted(missing_data_tests)}")

    unit_test_names = {node.get("name") for node in unit_tests.values()}
    missing_unit_tests = REQUIRED_UNIT_TESTS - unit_test_names
    if missing_unit_tests:
        failures.append(f"missing required unit tests: {sorted(missing_unit_tests)}")

    bad_results = []
    for result in run_results.get("results", []):
        status = str(result.get("status", "")).lower()
        if status not in SUCCESS_STATUSES:
            bad_results.append(f"{result.get('unique_id')}: {status}")
    if bad_results:
        failures.append(f"dbt nodes failed, errored, or skipped: {bad_results[:10]}")

    sensitive_findings = scan_repository(root)
    if sensitive_findings:
        failures.append(f"sensitive-term scan failed: {sensitive_findings}")

    counts = {
        "models": sum(node.get("resource_type") == "model" for node in nodes.values()),
        "data_tests": sum(node.get("resource_type") == "test" for node in nodes.values()),
        "unit_tests": len(unit_tests),
        "seeds": sum(node.get("resource_type") == "seed" for node in nodes.values()),
        "snapshots": sum(node.get("resource_type") == "snapshot" for node in nodes.values()),
        "sources": len(sources),
    }
    if failures:
        print("Artifact validation failed:")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)
    print("Artifact validation passed.")
    print("Resource counts: " + ", ".join(f"{name}={value}" for name, value in counts.items()))


if __name__ == "__main__":
    main()

