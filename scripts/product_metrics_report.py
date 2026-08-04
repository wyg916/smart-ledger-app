#!/usr/bin/env python3
"""Print sanitized 7-day and 30-day anonymous product metrics."""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def _fetch(base_url: str, token: str, days: int) -> dict[str, Any]:
    query = urlencode({"days": days})
    request = Request(
        f"{base_url.rstrip('/')}/api/v1/internal/metrics/overview?{query}",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urlopen(request, timeout=10) as response:  # noqa: S310 - caller chooses API URL
        return json.load(response)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Print anonymous Smart Ledger product metrics without identifiers or event data."
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("SMART_LEDGER_METRICS_BASE_URL", "http://127.0.0.1:8001"),
    )
    args = parser.parse_args()
    token = os.getenv("INTERNAL_METRICS_TOKEN", "")
    if not token:
        print("metrics_report=not_configured", file=sys.stderr)
        return 2

    reports: dict[str, Any] = {}
    try:
        for days in (7, 30):
            reports[f"last_{days}_days"] = _fetch(args.base_url, token, days)
    except HTTPError as error:
        print(f"metrics_report=failed http_status={error.code}", file=sys.stderr)
        return 1
    except (URLError, TimeoutError, json.JSONDecodeError):
        print("metrics_report=failed reason=unavailable", file=sys.stderr)
        return 1

    print(json.dumps(reports, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
