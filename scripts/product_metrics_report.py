#!/usr/bin/env python3
"""Export sanitized authenticated-user product metrics from the internal API."""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from datetime import date, datetime, timedelta, timezone
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

UTC_TIMEZONE = timezone.utc  # noqa: UP017 -- executable supports the system Python 3.10
DESCRIPTION = "Export aggregate authenticated-user metrics without identity or financial content."

ENDPOINTS = (
    "overview",
    "timeseries",
    "retention",
    "ai-usage",
    "ai-quota",
)


def _fetch(
    base_url: str,
    token: str,
    endpoint: str,
    start_date: date,
    end_date: date,
) -> dict[str, Any]:
    query = urlencode({"start_date": start_date.isoformat(), "end_date": end_date.isoformat()})
    request = Request(
        f"{base_url.rstrip('/')}/api/v1/internal/metrics/{endpoint}?{query}",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urlopen(request, timeout=15) as response:
        return json.load(response)


def _period(args: argparse.Namespace) -> tuple[date, date]:
    today = datetime.now(UTC_TIMEZONE).date()
    if args.start_date or args.end_date:
        if not args.start_date or not args.end_date:
            raise ValueError("custom range requires --start-date and --end-date")
        start = date.fromisoformat(args.start_date)
        end = date.fromisoformat(args.end_date)
    else:
        end = today
        start = end - timedelta(days=args.days - 1)
    if start > end or (end - start).days >= 400:
        raise ValueError("date range must contain 1 to 400 days")
    return start, end


def _csv_rows(reports: dict[str, dict[str, Any]]) -> list[list[Any]]:
    rows: list[list[Any]] = [["section", "date", "metric", "value"]]
    for section, payload in reports.items():
        if section == "timeseries":
            for point in payload.get("points", []):
                metric_date = point.get("metric_date", "")
                for key, value in point.items():
                    if key != "metric_date":
                        rows.append([section, metric_date, key, value])
            continue
        for key, value in payload.items():
            if key in {"start_date", "end_date"}:
                continue
            encoded = (
                json.dumps(value, ensure_ascii=False) if isinstance(value, (list, dict)) else value
            )
            rows.append([section, "", key, encoded])
    return rows


def _console(reports: dict[str, dict[str, Any]]) -> str:
    overview = reports["overview"]
    usage = reports["ai-usage"]
    quota = reports["ai-quota"]
    return "\n".join(
        (
            f"period={overview['start_date']}..{overview['end_date']}",
            f"dau={overview['dau']} wau={overview['wau']} mau={overview['mau']}",
            (
                f"active_users={overview['active_users']} "
                f"active_installations={overview['active_installations']} "
                f"sessions={overview['sessions']}"
            ),
            (
                f"transactions={overview['transaction_count']} ai_calls={usage['calls']} "
                f"ai_success_rate={usage['success_rate']}"
            ),
            (
                f"quota_blocked={quota['blocked']} tokens={usage['total_tokens']} "
                f"estimated_cost_usd={usage['estimated_cost_usd']}"
            ),
            f"d1_retention={overview['d1_retention']} d7_retention={overview['d7_retention']}",
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "--base-url",
        default=os.getenv("SMART_LEDGER_METRICS_BASE_URL", "http://127.0.0.1:8001"),
    )
    parser.add_argument("--days", type=int, choices=(1, 7, 30), default=30)
    parser.add_argument("--start-date", help="Custom inclusive start date (YYYY-MM-DD)")
    parser.add_argument("--end-date", help="Custom inclusive end date (YYYY-MM-DD)")
    parser.add_argument("--format", choices=("console", "json", "csv"), default="console")
    parser.add_argument("--output", help="Write JSON or CSV to this file instead of stdout")
    args = parser.parse_args()
    token = os.getenv("INTERNAL_METRICS_TOKEN", "")
    if not token:
        print("metrics_report=not_configured", file=sys.stderr)
        return 2
    try:
        start_date, end_date = _period(args)
        reports = {
            endpoint: _fetch(args.base_url, token, endpoint, start_date, end_date)
            for endpoint in ENDPOINTS
        }
    except ValueError as error:
        print(f"metrics_report=invalid_arguments reason={error}", file=sys.stderr)
        return 2
    except HTTPError as error:
        print(f"metrics_report=failed http_status={error.code}", file=sys.stderr)
        return 1
    except (URLError, TimeoutError, json.JSONDecodeError):
        print("metrics_report=failed reason=unavailable", file=sys.stderr)
        return 1

    if args.format == "json":
        output = json.dumps(reports, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    elif args.format == "csv":
        if args.output:
            with open(args.output, "w", encoding="utf-8", newline="") as target:
                csv.writer(target).writerows(_csv_rows(reports))
        else:
            csv.writer(sys.stdout).writerows(_csv_rows(reports))
        return 0
    else:
        output = _console(reports) + "\n"
    if args.output:
        with open(args.output, "w", encoding="utf-8") as target:
            target.write(output)
    else:
        sys.stdout.write(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
