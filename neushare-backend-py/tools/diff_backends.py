"""Replay every contract case against a Java and a Python backend, interleaved.

Both databases mutate in lockstep, so each pair of responses can be compared
directly. Writes a Markdown report and exits non-zero when any difference is
found.

Usage (from neushare-backend-py/):
    .venv/Scripts/python.exe tools/diff_backends.py \
        --java http://127.0.0.1:8081 --python http://127.0.0.1:8082
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")

from tests.contract.cases import CASES  # noqa: E402
from tests.contract.diff import canonicalize, diff_payloads, format_diffs  # noqa: E402
from tests.contract.replay import Backend, run_case  # noqa: E402

SEVERITY_ORDER = ["type", "missing", "extra", "value", "length", "numberType"]


def severity(diffs: list[dict]) -> str:
    kinds = {item["kind"] for item in diffs}
    if kinds & {"type", "missing", "extra"}:
        return "P0"
    if "value" in kinds:
        return "P1"
    return "P2"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--java", default="http://127.0.0.1:8081")
    parser.add_argument("--python", default="http://127.0.0.1:8082")
    parser.add_argument("--report", default="")
    parser.add_argument("--only", default="", help="只跑名字包含该子串的用例")
    parser.add_argument("--show", type=int, default=8, help="每个差异用例最多打印多少条")
    args = parser.parse_args()

    java = Backend(args.java)
    python = Backend(args.python)
    try:
        java.login_all()
        python.login_all()
    except Exception as exc:  # noqa: BLE001
        print(f"登录失败: {exc}", file=sys.stderr)
        return 2

    ctx_java: dict = {}
    ctx_python: dict = {}
    rows: list[dict] = []
    total = passed = 0

    try:
        for case in CASES:
            if args.only and args.only not in case["name"]:
                continue
            total += 1
            row = {"name": case["name"], "diffs": [], "errors": [], "severity": ""}
            try:
                res_java = run_case(java, case, ctx_java)
            except Exception as exc:  # noqa: BLE001
                row["errors"].append(f"java: {type(exc).__name__}: {exc}")
                rows.append(row)
                print(f"[ERROR] {case['name']} java: {exc}", file=sys.stderr)
                continue
            try:
                res_python = run_case(python, case, ctx_python)
            except Exception as exc:  # noqa: BLE001
                row["errors"].append(f"python: {type(exc).__name__}: {exc}")
                rows.append(row)
                print(f"[ERROR] {case['name']} python: {exc}", file=sys.stderr)
                continue

            row["javaStatus"] = res_java.status
            row["pythonStatus"] = res_python.status
            unordered = case.get("unordered")
            row["diffs"] = diff_payloads(
                canonicalize(res_java.normalized, unordered),
                canonicalize(res_python.normalized, unordered),
            )
            if row["diffs"]:
                row["severity"] = severity(row["diffs"])
                print(format_diffs(case["name"], row["diffs"], limit=args.show))
                print()
            else:
                passed += 1
            rows.append(row)
    finally:
        java.close()
        python.close()

    failed = [row for row in rows if row["diffs"] or row["errors"]]
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    report_path = Path(args.report) if args.report else (
        ROOT / "tests/contract/reports" / f"diff-{stamp}.md")
    report_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        f"# 契约差异报告 {stamp}",
        "",
        f"- Java 基准: `{args.java}`",
        f"- Python 实现: `{args.python}`",
        f"- 用例总数: {total}，完全一致: {passed}，存在差异: {len(failed)}",
        "",
        "| 用例 | Java | Python | 级别 | 差异数 | 首个差异字段 |",
        "|---|---|---|---|---|---|",
    ]
    for row in rows:
        if not row["diffs"] and not row["errors"]:
            continue
        first = row["diffs"][0]["path"] if row["diffs"] else row["errors"][0][:60]
        lines.append(
            f"| `{row['name']}` | {row.get('javaStatus', '-')} | "
            f"{row.get('pythonStatus', '-')} | {row.get('severity') or 'ERROR'} | "
            f"{len(row['diffs'])} | `{first}` |"
        )
    lines.append("")
    lines.append("## 差异明细")
    lines.append("")
    for row in rows:
        if not row["diffs"]:
            continue
        lines.append(f"### `{row['name']}`（{row['severity']}，"
                     f"Java {row.get('javaStatus')} / Python {row.get('pythonStatus')}）")
        lines.append("")
        lines.append("```")
        lines.extend(format_diffs(row["name"], row["diffs"], limit=40).splitlines()[1:])
        lines.append("```")
        lines.append("")
    report_path.write_text("\n".join(lines), encoding="utf-8")

    json_path = report_path.with_suffix(".json")
    json_path.write_text(json.dumps(
        {"java": args.java, "python": args.python, "total": total,
         "passed": passed, "rows": rows}, ensure_ascii=False, indent=1), encoding="utf-8")

    print("=" * 72)
    print(f"用例 {total} | 一致 {passed} | 差异 {len(failed)}")
    for level in ("P0", "P1", "P2", "ERROR"):
        names = [row["name"] for row in failed
                 if (row.get("severity") or "ERROR") == level]
        if names:
            print(f"  {level}: {len(names)} -> {', '.join(names[:8])}"
                  + (" ..." if len(names) > 8 else ""))
    print(f"报告: {report_path}")
    print(f"机器可读: {json_path}")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
