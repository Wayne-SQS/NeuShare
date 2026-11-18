"""Shared pytest fixtures for the NeuShare Python backend test suite."""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


@pytest.fixture(scope="session")
def base_url() -> str:
    """Target backend; override with CONTRACT_BASE_URL when testing a deployment."""
    import os

    return os.environ.get("CONTRACT_BASE_URL", "http://127.0.0.1:8080")
