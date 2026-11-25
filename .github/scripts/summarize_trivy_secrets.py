#!/usr/bin/env python3
"""Summarize Trivy secret findings without exposing matched content."""

import argparse
import json
from collections import Counter
from pathlib import Path


SEVERITY_RANK = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1}


def cell(value):
    return str(value or "—").replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("scope")
    parser.add_argument("--fail-on-findings", action="store_true")
    args = parser.parse_args()

    report = json.loads(args.report.read_text())
    findings = {}
    total = 0
    for result in report.get("Results") or []:
        target = result.get("Target") or "unknown target"
        for secret in result.get("Secrets") or []:
            total += 1
            rule = secret.get("RuleID") or "unknown rule"
            line = secret.get("StartLine") or "—"
            key = (rule, target, line)
            severity = secret.get("Severity") or "UNKNOWN"
            previous = findings.get(key)
            if previous is None or SEVERITY_RANK.get(severity, 0) > SEVERITY_RANK.get(previous, 0):
                findings[key] = severity

    ordered = sorted(findings.items(), key=lambda item: (
        -SEVERITY_RANK.get(item[1], 0), item[0][0], item[0][1], str(item[0][2])
    ))
    counts = Counter(findings.values())
    print(f"## Trivy secrets: {cell(args.scope)}\n")
    print(f"**{total} matches in {len(findings)} distinct locations** "
          f"({counts['CRITICAL']} critical, {counts['HIGH']} high, "
          f"{counts['MEDIUM']} medium, {counts['LOW']} low).\n")
    if ordered:
        print("Matched values and source snippets are omitted from CI logs. "
              "Run Trivy locally to inspect a finding.\n")
        print("| Severity | Rule | Target | Line |")
        print("| --- | --- | --- | ---: |")
        for (rule, target, line), severity in ordered[:20]:
            print(f"| {cell(severity)} | {cell(rule)} | {cell(target)} | {cell(line)} |")
        if len(ordered) > 20:
            print(f"\nShowing 20 of {len(ordered)} locations.")
    if args.fail_on_findings and total:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
