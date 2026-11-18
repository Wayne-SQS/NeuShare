"""Capture a golden contract baseline from a running backend.

Usage (from neushare-backend-py/):
    .venv/Scripts/python.exe tools/capture_golden.py --base http://127.0.0.1:8081 --label java

The Java backend is the reference implementation: run this against it once,
commit ``tests/contract/golden/golden.json``, and from then on the Python
backend can be validated long after the Java service is gone.
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
from tests.contract.replay import Backend, run_case  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://127.0.0.1:8081")
    parser.add_argument("--label", default="java")
    parser.add_argument("--out", default=str(ROOT / "tests/contract/golden/golden.json"))
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    backend = Backend(args.base)
    try:
        backend.login_all()
    except Exception as exc:  # noqa: BLE001
        print(f"无法登录 {args.base}: {exc}", file=sys.stderr)
        return 2

    ctx: dict = {}
    records: dict = {}
    failures = 0
    try:
        for index, case in enumerate(CASES, start=1):
            try:
                result = run_case(backend, case, ctx)
                records[case["name"]] = result.normalized
                if not args.quiet and index % 10 == 0:
                    print(f"  {index}/{len(CASES)} ...")
            except Exception as exc:  # noqa: BLE001
                failures += 1
                records[case["name"]] = {"error": f"{type(exc).__name__}: {exc}"}
                print(f"  [FAIL] {case['name']}: {exc}", file=sys.stderr)
    finally:
        backend.close()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {
            "label": args.label,
            "base": args.base,
            "capturedAt": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "caseCount": len(CASES),
            "mutatingCount": sum(1 for case in CASES if case.get("mutating")),
        },
        "cases": records,
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"已写入 {out_path} （{len(records)} 个用例，{failures} 个采集失败）")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
