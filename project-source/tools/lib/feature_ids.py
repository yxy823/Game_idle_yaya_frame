"""Feature IDs: ``F<Product>-<NNN>`` for Product work, ``B``/``R``/``M<NNN>`` for engineering changes."""

from __future__ import annotations

import re

FEATURE_ID = r"(?:F\d{2}-\d{3}|[BRM]\d{3})"
FEATURE_ID_RE = re.compile(FEATURE_ID)
FEATURE_ID_HINT = "F<Product NN>-<NNN> (for example F01-003), or B/R/M followed by three digits"
ENGINEERING_PREFIX = {"B": "bug", "R": "refactor", "M": "maintenance"}


def series(fid: str) -> str:
    """The numbering series an ID belongs to: ``F01`` for Product 01, otherwise its prefix letter."""
    return fid[:3] if fid.startswith("F") else fid[0]


def number(fid: str) -> int:
    """The position of the ID within its series, starting at 1."""
    return int(fid[-3:])
