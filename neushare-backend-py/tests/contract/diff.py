"""Field-level diff between two normalized responses."""
from __future__ import annotations

import copy


def canonicalize(normalized: dict, specs) -> dict:
    """Return a copy with the given arrays sorted, so ties are order-insensitive.

    ``specs`` is a list of ``("<path under body.json>", "<sort key>")`` pairs, e.g.
    ``[("data.categoryDistribution", "name")]``. Used where the Java reference is
    itself non-deterministic: distribution rankings sorted only by count leave ties
    in ``HashMap`` iteration order.
    """
    if not specs:
        return normalized
    body = normalized.get("body") or {}
    payload = body.get("json")
    if payload is None:
        return normalized

    data = copy.deepcopy(payload)
    for path, key in specs:
        parts = path.split(".")
        cursor = data
        for part in parts[:-1]:
            if not isinstance(cursor, dict) or part not in cursor:
                cursor = None
                break
            cursor = cursor[part]
        if not isinstance(cursor, dict):
            continue
        items = cursor.get(parts[-1])
        if isinstance(items, list):
            cursor[parts[-1]] = sorted(
                items, key=lambda item: (item.get(key) is None, item.get(key))
            )
    result = dict(normalized)
    result["body"] = {**body, "json": data}
    return result


def _type_name(value) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def diff_payloads(expected, actual, path: str = "$") -> list[dict]:
    """Return every difference between the golden (expected) and live (actual) value."""
    diffs: list[dict] = []

    if isinstance(expected, dict) and isinstance(actual, dict):
        for key in sorted(set(expected) | set(actual)):
            child = f"{path}.{key}"
            if key not in actual:
                diffs.append({"path": child, "kind": "missing", "expected": expected[key],
                              "actual": "<absent>"})
            elif key not in expected:
                diffs.append({"path": child, "kind": "extra", "expected": "<absent>",
                              "actual": actual[key]})
            else:
                diffs.extend(diff_payloads(expected[key], actual[key], child))
        return diffs

    if isinstance(expected, list) and isinstance(actual, list):
        if len(expected) != len(actual):
            diffs.append({"path": f"{path}.length", "kind": "length",
                          "expected": len(expected), "actual": len(actual)})
        for index in range(min(len(expected), len(actual))):
            diffs.extend(diff_payloads(expected[index], actual[index], f"{path}[{index}]"))
        return diffs

    if _type_name(expected) != _type_name(actual):
        # int vs float is worth reporting but not the same class of bug as a
        # string where the client expects a number.
        numeric = {_type_name(expected), _type_name(actual)} == {"integer", "float"}
        diffs.append({"path": path, "kind": "numberType" if numeric else "type",
                      "expected": expected, "actual": actual})
        return diffs

    if expected != actual:
        diffs.append({"path": path, "kind": "value", "expected": expected, "actual": actual})
    return diffs


def format_diffs(case_name: str, diffs: list[dict], limit: int = 12) -> str:
    lines = [f"[{case_name}] {len(diffs)} 处差异"]
    for item in diffs[:limit]:
        lines.append(
            f"  - {item['kind']:10} {item['path']}\n"
            f"      Java : {item['expected']!r}\n"
            f"      Python: {item['actual']!r}"
        )
    if len(diffs) > limit:
        lines.append(f"  ... 另有 {len(diffs) - limit} 处")
    return "\n".join(lines)
