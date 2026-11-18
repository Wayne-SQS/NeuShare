"""Golden contract tests: every read-only case must match the Java baseline.

The baseline in ``golden/golden.json`` is captured from the reference Java
backend with ``tools/capture_golden.py``. Replaying it needs a backend whose
database is in seed state.

Environment variables:
    CONTRACT_BASE_URL     backend under test (default http://127.0.0.1:8080)
    CONTRACT_ALLOW_WRITES "1" to also replay mutating cases (needs a disposable DB)
"""
from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

from tests.contract.cases import CASES
from tests.contract.diff import canonicalize, diff_payloads, format_diffs
from tests.contract.replay import Backend, run_case

GOLDEN_FILE = Path(__file__).parent / "golden" / "golden.json"
ALLOW_WRITES = os.environ.get("CONTRACT_ALLOW_WRITES") == "1"

pytestmark = pytest.mark.skipif(
    not GOLDEN_FILE.exists(),
    reason="缺少契约黄金基准，先运行 tools/capture_golden.py",
)

READ_ONLY_CASES = [case for case in CASES if not case.get("mutating")]


@pytest.fixture(scope="session")
def golden() -> dict:
    return json.loads(GOLDEN_FILE.read_text(encoding="utf-8"))["cases"]


@pytest.fixture(scope="session")
def live_responses(base_url) -> dict:
    """Replay the suite once, in declaration order, and keep every response."""
    backend = Backend(base_url)
    try:
        backend.login_all()
        ctx: dict = {}
        collected: dict = {}
        for case in CASES:
            if case.get("mutating") and not ALLOW_WRITES:
                continue
            collected[case["name"]] = run_case(backend, case, ctx)
        return collected
    finally:
        backend.close()


@pytest.mark.parametrize("case", READ_ONLY_CASES, ids=[c["name"] for c in READ_ONLY_CASES])
def test_contract_matches_java_golden(case, golden, live_responses):
    expected = golden.get(case["name"])
    assert expected is not None, f"黄金基准里缺少用例 {case['name']}"

    actual = live_responses[case["name"]]
    assert actual.error is None, actual.error

    diffs = diff_payloads(
        canonicalize(expected, case.get("unordered")),
        canonicalize(actual.normalized, case.get("unordered")),
    )
    assert not diffs, format_diffs(case["name"], diffs)
