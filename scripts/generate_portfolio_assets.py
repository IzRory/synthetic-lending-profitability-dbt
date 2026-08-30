"""Create portfolio images from the dbt manifest and DuckDB marts."""

from __future__ import annotations

import json
from collections import defaultdict, deque
from pathlib import Path

import duckdb
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
BACKGROUND = "#0B1220"
PANEL = "#172033"
PANEL_HIGHLIGHT = "#214C73"
TEXT = "#F4F7FB"
MUTED = "#AEBBD0"
ACCENT = "#58C3B1"
LINE = "#6682A3"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def draw_arrow(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int]) -> None:
    draw.line([start, end], fill=LINE, width=3)
    x, y = end
    draw.polygon([(x, y), (x - 10, y - 6), (x - 10, y + 6)], fill=LINE)


def lineage_nodes(manifest: dict[str, object], center_name: str) -> tuple[dict[str, int], set[tuple[str, str]]]:
    nodes = manifest["nodes"]
    name_to_id = {node["name"]: node_id for node_id, node in nodes.items() if node.get("resource_type") == "model"}
    center_id = name_to_id[center_name]
    parent_map = manifest["parent_map"]
    child_map = manifest["child_map"]
    layers = {center_id: 0}
    edges: set[tuple[str, str]] = set()

    queue: deque[tuple[str, int]] = deque([(center_id, 0)])
    while queue:
        node_id, depth = queue.popleft()
        if depth <= -3:
            continue
        for parent_id in parent_map.get(node_id, []):
            parent = nodes.get(parent_id)
            if not parent or parent.get("resource_type") not in {"model", "snapshot"}:
                continue
            edges.add((parent_id, node_id))
            if parent_id not in layers or layers[parent_id] < depth - 1:
                layers[parent_id] = depth - 1
                queue.append((parent_id, depth - 1))

    queue = deque([(center_id, 0)])
    while queue:
        node_id, depth = queue.popleft()
        if depth >= 2:
            continue
        for child_id in child_map.get(node_id, []):
            child = nodes.get(child_id)
            if not child or child.get("resource_type") != "model":
                continue
            edges.add((node_id, child_id))
            if child_id not in layers:
                layers[child_id] = depth + 1
                queue.append((child_id, depth + 1))
    return layers, edges


def create_lineage_image() -> None:
    manifest = json.loads((ROOT / "target/manifest.json").read_text(encoding="utf-8"))
    nodes = manifest["nodes"]
    layers, edges = lineage_nodes(manifest, "fct_loan_profitability")
    by_layer: dict[int, list[str]] = defaultdict(list)
    for node_id, layer in layers.items():
        by_layer[layer].append(node_id)
    for node_ids in by_layer.values():
        node_ids.sort(key=lambda node_id: nodes[node_id]["name"])

    image = Image.new("RGB", (2260, 1000), BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((70, 45), "dbt lineage: fct_loan_profitability", font=font(42, True), fill=TEXT)
    draw.text((70, 100), "Direct model lineage extracted from target/manifest.json", font=font(22), fill=MUTED)

    layer_x = {-3: 50, -2: 420, -1: 790, 0: 1160, 1: 1530, 2: 1900}
    box_width = 320
    box_height = 62
    positions: dict[str, tuple[int, int, int, int]] = {}
    for layer in sorted(by_layer):
        node_ids = by_layer[layer]
        x = layer_x[layer]
        available = 780
        gap = max(12, min(45, (available - len(node_ids) * box_height) // max(1, len(node_ids) - 1)))
        y_start = 170 + max(0, (available - (len(node_ids) * box_height + (len(node_ids) - 1) * gap)) // 2)
        for index, node_id in enumerate(node_ids):
            y = y_start + index * (box_height + gap)
            positions[node_id] = (x, y, x + box_width, y + box_height)

    for parent_id, child_id in edges:
        if parent_id not in positions or child_id not in positions:
            continue
        parent = positions[parent_id]
        child = positions[child_id]
        draw_arrow(draw, (parent[2], (parent[1] + parent[3]) // 2), (child[0], (child[1] + child[3]) // 2))

    for node_id, box in positions.items():
        is_center = nodes[node_id]["name"] == "fct_loan_profitability"
        draw.rounded_rectangle(box, radius=12, fill=PANEL_HIGHLIGHT if is_center else PANEL, outline=ACCENT if is_center else LINE, width=3)
        name = nodes[node_id]["name"]
        if len(name) > 34:
            name = name[:32] + ".."
        draw.text((box[0] + 15, box[1] + 18), name, font=font(18, is_center), fill=TEXT)

    draw.text((70, 950), "Synthetic portfolio project | Summit Ridge Lending", font=font(18), fill=MUTED)
    image.save(ASSETS / "dbt-lineage.png")


def create_sample_output_image() -> None:
    connection = duckdb.connect(str(ROOT / "target/ci.duckdb"), read_only=True)
    latest_month = connection.execute("select max(month_end_date) from analytics.fct_monthly_branch_pnl").fetchone()[0]
    rows = connection.execute(
        """
        select
            branch_name,
            region_name,
            funded_loan_count,
            funded_amount,
            total_revenue,
            total_cost,
            profit_amount,
            profit_margin_bps
        from analytics.fct_monthly_branch_pnl
        where month_end_date = ?
        order by profit_amount desc
        limit 9
        """,
        [latest_month],
    ).fetchall()
    connection.close()

    image = Image.new("RGB", (1800, 900), BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((65, 40), "Monthly branch P&L sample", font=font(42, True), fill=TEXT)
    draw.text((65, 95), f"Month end {latest_month} | fictional values", font=font(22), fill=MUTED)

    headers = ["Branch", "Region", "Loans", "Funded amount", "Revenue", "Cost", "Profit", "Margin bps"]
    widths = [245, 200, 90, 225, 195, 195, 195, 145]
    x_positions = [55]
    for width in widths[:-1]:
        x_positions.append(x_positions[-1] + width)
    table_top = 165
    row_height = 65
    draw.rounded_rectangle((45, table_top - 10, 1755, table_top + row_height * 10), radius=12, fill=PANEL)
    for index, header in enumerate(headers):
        draw.text((x_positions[index] + 10, table_top + 15), header, font=font(18, True), fill=ACCENT)
    draw.line((55, table_top + row_height, 1740, table_top + row_height), fill=LINE, width=2)

    for row_index, row in enumerate(rows, start=1):
        values = [
            str(row[0]).replace("Summit ", ""),
            str(row[1]).replace("Summit ", ""),
            f"{row[2]:,}",
            f"${row[3]:,.2f}",
            f"${row[4]:,.2f}",
            f"${row[5]:,.2f}",
            f"${row[6]:,.2f}",
            f"{row[7]:,.2f}",
        ]
        y = table_top + row_height * row_index + 16
        if row_index % 2 == 0:
            draw.rectangle((55, y - 13, 1740, y + 36), fill="#1B2840")
        for column_index, value in enumerate(values):
            draw.text((x_positions[column_index] + 10, y), value, font=font(18), fill=TEXT)

    draw.text((65, 840), "All records and calculations are deterministic synthetic examples.", font=font(18), fill=MUTED)
    image.save(ASSETS / "sample-profitability-output.png")


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    create_lineage_image()
    create_sample_output_image()
    print("Created assets/dbt-lineage.png and assets/sample-profitability-output.png")


if __name__ == "__main__":
    main()
