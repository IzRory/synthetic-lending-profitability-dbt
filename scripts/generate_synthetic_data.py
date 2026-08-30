"""Generate deterministic fictional lending inputs for Summit Ridge Lending."""

from __future__ import annotations

import argparse
import calendar
import csv
import random
from collections import defaultdict
from datetime import date, datetime, time, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from typing import Iterable


DEFAULT_SEED = 20260830
MONEY = Decimal("0.01")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--row-count", type=int, default=25_000)
    parser.add_argument("--start-date", type=date.fromisoformat, default=date(2024, 8, 1))
    parser.add_argument("--end-date", type=date.fromisoformat, default=date(2026, 7, 31))
    parser.add_argument("--output-dir", type=Path, default=Path("seeds/generated"))
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    parser.add_argument(
        "--inject-failures",
        action="store_true",
        help="Create one bad funding total, one duplicate loan, and one orphaned program.",
    )
    return parser.parse_args()


def month_ends(start_date: date, end_date: date) -> list[date]:
    if start_date > end_date:
        raise ValueError("start-date must be on or before end-date")
    cursor = date(start_date.year, start_date.month, 1)
    result: list[date] = []
    while cursor <= end_date:
        last_day = calendar.monthrange(cursor.year, cursor.month)[1]
        month_end = date(cursor.year, cursor.month, last_day)
        if month_end >= start_date and month_end <= end_date:
            result.append(month_end)
        cursor = date(cursor.year + (cursor.month == 12), cursor.month % 12 + 1, 1)
    if not result:
        raise ValueError("date range must include at least one month end")
    return result


def money(value: Decimal | float | int | str) -> str:
    return str(Decimal(str(value)).quantize(MONEY, rounding=ROUND_HALF_UP))


def timestamp(value: date, hour: int = 12) -> str:
    return datetime.combine(value, time(hour=hour)).isoformat(timespec="seconds")


def write_csv(path: Path, fieldnames: list[str], rows: Iterable[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def build_programs(start_date: date) -> list[dict[str, object]]:
    families = ["Conventional", "Government", "Jumbo", "Community"]
    rows = []
    for number in range(1, 13):
        family = families[(number - 1) % len(families)]
        rows.append(
            {
                "program_id": f"PG{number:03d}",
                "program_name": f"Summit {family} {number:02d}",
                "product_family": family,
                "default_margin_bps": 260 + (number * 18),
                "effective_start_date": start_date.isoformat(),
                "effective_end_date": "",
            }
        )
    return rows


def build_hierarchy(start_date: date, months: list[date]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    change_date = months[len(months) // 2].replace(day=1)
    changing_branches = {7, 14, 21, 28, 35, 42, 49, 56}
    for branch_number in range(1, 61):
        initial_region = ((branch_number - 1) % 8) + 1
        periods = [(start_date, None, initial_region)]
        if branch_number in changing_branches:
            moved_region = ((initial_region + 1) % 8) + 1
            periods = [
                (start_date, change_date - timedelta(days=1), initial_region),
                (change_date, None, moved_region),
            ]
        for effective_start, effective_end, region_number in periods:
            rows.append(
                {
                    "branch_id": f"BR{branch_number:03d}",
                    "branch_name": f"Summit Branch {branch_number:02d}",
                    "region_id": f"RG{region_number:02d}",
                    "region_name": f"Summit Region {region_number}",
                    "effective_start_date": effective_start.isoformat(),
                    "effective_end_date": effective_end.isoformat() if effective_end else "",
                    "is_active": "true" if effective_end is None else "false",
                }
            )
    return rows


def build_data(args: argparse.Namespace) -> dict[str, list[dict[str, object]]]:
    rng = random.Random(args.seed)
    months = month_ends(args.start_date, args.end_date)
    programs = build_programs(args.start_date)
    hierarchy = build_hierarchy(args.start_date, months)
    partner_ids = [f"PT{number:02d}" for number in range(1, 6)]

    loans: list[dict[str, object]] = []
    partner_statements: list[dict[str, object]] = []
    credit_transactions: list[dict[str, object]] = []
    commissions: list[dict[str, object]] = []
    overrides: list[dict[str, object]] = []
    trueups: list[dict[str, object]] = []
    margin_adjustments: list[dict[str, object]] = []
    funding_groups: dict[tuple[str, str], dict[str, Decimal | int]] = defaultdict(
        lambda: {"count": 0, "amount": Decimal("0")}
    )

    for number in range(1, args.row_count + 1):
        loan_id = f"LN{number:08d}"
        month_end = months[(number - 1) % len(months)]
        funded_day = rng.randint(1, month_end.day)
        funded_date = month_end.replace(day=funded_day)
        branch_id = f"BR{rng.randint(1, 60):03d}"
        program_number = rng.randint(1, 12)
        program_id = f"PG{program_number:03d}"
        partner_id = rng.choice(partner_ids) if rng.random() < 0.36 else ""
        funded_amount = Decimal(rng.randrange(1_200, 8_001)) * Decimal("100")
        default_margin = Decimal(programs[program_number - 1]["default_margin_bps"])
        base_margin_bps = default_margin + Decimal(rng.randint(-30, 30))
        origination_fee = Decimal(rng.randrange(5_000, 30_001)) / Decimal("10")
        created_date = funded_date - timedelta(days=rng.randint(5, 45))
        updated_date = funded_date + timedelta(days=rng.randint(0, 5))

        loan = {
            "loan_id": loan_id,
            "funded_date": funded_date.isoformat(),
            "month_end_date": month_end.isoformat(),
            "branch_id": branch_id,
            "program_id": program_id,
            "partner_id": partner_id,
            "funded_amount": money(funded_amount),
            "base_margin_bps": money(base_margin_bps),
            "origination_fee_amount": money(origination_fee),
            "status": "FUNDED",
            "created_at": timestamp(created_date, 9),
            "updated_at": timestamp(updated_date, 14),
        }
        loans.append(loan)

        group = funding_groups[(month_end.isoformat(), branch_id)]
        group["count"] = int(group["count"]) + 1
        group["amount"] = Decimal(group["amount"]) + funded_amount

        if partner_id:
            partner_bps = Decimal(18 + (int(partner_id[-2:]) * 4))
            partner_revenue = funded_amount * partner_bps / Decimal("10000")
            partner_statements.append(
                {
                    "statement_id": f"PS{len(partner_statements) + 1:08d}",
                    "loan_id": loan_id,
                    "partner_id": partner_id,
                    "partner_revenue_amount": money(partner_revenue),
                    "statement_month": month_end.isoformat(),
                    "received_at": timestamp(month_end + timedelta(days=5), 10),
                }
            )

        transaction_count = 2 if rng.random() < 0.60 else 1
        for sequence in range(1, transaction_count + 1):
            cost = Decimal(rng.randrange(2500, 18_001)) / Decimal("100")
            credit_transactions.append(
                {
                    "credit_transaction_id": f"CT{len(credit_transactions) + 1:09d}",
                    "loan_id": loan_id,
                    "transaction_date": (created_date + timedelta(days=sequence)).isoformat(),
                    "credit_cost_amount": money(cost),
                    "transaction_type": "REPORT" if sequence == 1 else "SUPPLEMENT",
                }
            )

        commission_rate_bps = Decimal(rng.randint(62, 112))
        commissions.append(
            {
                "commission_id": f"CM{number:08d}",
                "loan_id": loan_id,
                "commission_month": month_end.isoformat(),
                "commission_amount": money(funded_amount * commission_rate_bps / Decimal("10000")),
                "commission_type": "STANDARD",
            }
        )

        if rng.random() < 0.22:
            override_rate_bps = Decimal(rng.randint(5, 16))
            overrides.append(
                {
                    "override_id": f"OV{len(overrides) + 1:08d}",
                    "loan_id": loan_id,
                    "override_month": month_end.isoformat(),
                    "override_amount": money(funded_amount * override_rate_bps / Decimal("10000")),
                    "override_type": "BRANCH_SUPPORT",
                }
            )

        if rng.random() < 0.13:
            trueup_value = Decimal(rng.randrange(-75000, 125001)) / Decimal("100")
            trueups.append(
                {
                    "trueup_id": f"TU{len(trueups) + 1:08d}",
                    "loan_id": loan_id,
                    "posting_month": month_end.isoformat(),
                    "trueup_amount": money(trueup_value),
                    "trueup_reason": "SYNTHETIC_RECLASS",
                }
            )

        if rng.random() < 0.12:
            adjustment = Decimal(rng.randrange(-100000, 200001)) / Decimal("100")
            margin_adjustments.append(
                {
                    "margin_adjustment_id": f"MA{len(margin_adjustments) + 1:08d}",
                    "loan_id": loan_id,
                    "adjustment_month": month_end.isoformat(),
                    "margin_adjustment_amount": money(adjustment),
                    "adjustment_reason": "SYNTHETIC_PRICING_ADJUSTMENT",
                }
            )

    funding_statements: list[dict[str, object]] = []
    for month_end, branch_id in sorted(funding_groups):
        values = funding_groups[(month_end, branch_id)]
        funding_statements.append(
            {
                "month_end_date": month_end,
                "branch_id": branch_id,
                "statement_loan_count": values["count"],
                "statement_funded_amount": money(Decimal(values["amount"])),
                "statement_source": "SYNTHETIC_MONTH_END_CONTROL",
            }
        )

    branch_overhead: list[dict[str, object]] = []
    for month_end in months:
        for branch_number in range(1, 61):
            branch_overhead.append(
                {
                    "month_end_date": month_end.isoformat(),
                    "branch_id": f"BR{branch_number:03d}",
                    "monthly_branch_overhead": money(rng.randrange(2_500_000, 6_000_001) / 100),
                    "overhead_basis": "SYNTHETIC_FIXED_ALLOCATION",
                }
            )

    if args.inject_failures and loans:
        funding_statements[0]["statement_funded_amount"] = money(
            Decimal(str(funding_statements[0]["statement_funded_amount"])) + Decimal("123.45")
        )
        loans[1]["program_id"] = "PG999"
        loans.append(dict(loans[0]))

    return {
        "raw_loans": loans,
        "raw_branch_hierarchy": hierarchy,
        "raw_programs": programs,
        "raw_funding_statements": funding_statements,
        "raw_partner_statements": partner_statements,
        "raw_credit_transactions": credit_transactions,
        "raw_commissions": commissions,
        "raw_overrides": overrides,
        "raw_trueups": trueups,
        "raw_margin_adjustments": margin_adjustments,
        "raw_branch_overhead": branch_overhead,
    }


FIELDNAMES = {
    "raw_loans": [
        "loan_id",
        "funded_date",
        "month_end_date",
        "branch_id",
        "program_id",
        "partner_id",
        "funded_amount",
        "base_margin_bps",
        "origination_fee_amount",
        "status",
        "created_at",
        "updated_at",
    ],
    "raw_branch_hierarchy": [
        "branch_id",
        "branch_name",
        "region_id",
        "region_name",
        "effective_start_date",
        "effective_end_date",
        "is_active",
    ],
    "raw_programs": [
        "program_id",
        "program_name",
        "product_family",
        "default_margin_bps",
        "effective_start_date",
        "effective_end_date",
    ],
    "raw_funding_statements": [
        "month_end_date",
        "branch_id",
        "statement_loan_count",
        "statement_funded_amount",
        "statement_source",
    ],
    "raw_partner_statements": [
        "statement_id",
        "loan_id",
        "partner_id",
        "partner_revenue_amount",
        "statement_month",
        "received_at",
    ],
    "raw_credit_transactions": [
        "credit_transaction_id",
        "loan_id",
        "transaction_date",
        "credit_cost_amount",
        "transaction_type",
    ],
    "raw_commissions": [
        "commission_id",
        "loan_id",
        "commission_month",
        "commission_amount",
        "commission_type",
    ],
    "raw_overrides": ["override_id", "loan_id", "override_month", "override_amount", "override_type"],
    "raw_trueups": ["trueup_id", "loan_id", "posting_month", "trueup_amount", "trueup_reason"],
    "raw_margin_adjustments": [
        "margin_adjustment_id",
        "loan_id",
        "adjustment_month",
        "margin_adjustment_amount",
        "adjustment_reason",
    ],
    "raw_branch_overhead": ["month_end_date", "branch_id", "monthly_branch_overhead", "overhead_basis"],
}


def main() -> None:
    args = parse_args()
    if args.row_count < 1:
        raise ValueError("row-count must be positive")
    data = build_data(args)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name, rows in data.items():
        write_csv(args.output_dir / f"{name}.csv", FIELDNAMES[name], rows)
    counts = ", ".join(f"{name}={len(rows):,}" for name, rows in data.items())
    mode = "defect fixture" if args.inject_failures else "clean dataset"
    print(f"Generated {mode} with seed {args.seed}: {counts}")


if __name__ == "__main__":
    main()

