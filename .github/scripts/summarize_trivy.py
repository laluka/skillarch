#!/usr/bin/env python3
"""Show the highest-ranked unique vulnerabilities from a Trivy JSON report."""

import json
import sys
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse


SEVERITY_RANK = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1}


def cell(value):
    return str(value or "—").replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def score(vulnerability):
    scores = []
    for source in vulnerability.get("CVSS") or {}:
        for key in ("V4Score", "V3Score", "V2Score"):
            value = vulnerability["CVSS"][source].get(key)
            if isinstance(value, (int, float)):
                scores.append(float(value))
    return max(scores, default=0.0)


def main(report_path):
    report = json.loads(Path(report_path).read_text())
    findings = {}
    raw_count = 0
    for result in report.get("Results") or []:
        target = result.get("Target") or "unknown target"
        for vulnerability in result.get("Vulnerabilities") or []:
            identifier = vulnerability.get("VulnerabilityID")
            if not identifier:
                continue
            raw_count += 1
            entry = findings.setdefault(identifier, {
                "severity": "UNKNOWN", "score": 0.0, "targets": set(),
                "packages": set(), "fixed": set(), "url": "",
            })
            severity = vulnerability.get("Severity") or "UNKNOWN"
            if SEVERITY_RANK.get(severity, 0) > SEVERITY_RANK.get(entry["severity"], 0):
                entry["severity"] = severity
            entry["score"] = max(entry["score"], score(vulnerability))
            entry["targets"].add(target)
            if vulnerability.get("PkgName"):
                entry["packages"].add(vulnerability["PkgName"])
            if vulnerability.get("FixedVersion"):
                entry["fixed"].add(vulnerability["FixedVersion"])
            url = vulnerability.get("PrimaryURL") or ""
            if urlparse(url).scheme in ("http", "https") and not entry["url"]:
                entry["url"] = url

    ordered = sorted(findings.items(), key=lambda item: (
        -SEVERITY_RANK.get(item[1]["severity"], 0),
        -item[1]["score"],
        -len(item[1]["targets"]),
        item[0],
    ))
    counts = Counter(entry["severity"] for entry in findings.values())
    print("## Full-image vulnerability report (advisory)\n")
    print(f"{raw_count} package findings; **{len(findings)} unique vulnerability IDs** "
          f"({counts['CRITICAL']} critical, {counts['HIGH']} high). "
          "Duplicates across packages and targets are counted once.\n")
    print("Severity describes the dependency advisory; it does not establish that "
          "the affected code is reachable in this image. CVSS is the highest score "
          "reported for each ID.\n")
    print("| Vulnerability | Severity | Max CVSS | Targets | Example target | Packages | Fixed version(s) |")
    print("| --- | --- | ---: | ---: | --- | --- | --- |")
    for identifier, entry in ordered[:15]:
        name = cell(identifier)
        if entry["url"]:
            name = f"[{name}]({entry['url']})"
        packages = ", ".join(sorted(entry["packages"])[:3])
        if len(entry["packages"]) > 3:
            packages += f" (+{len(entry['packages']) - 3})"
        fixed = ", ".join(sorted(entry["fixed"])[:3])
        if len(entry["fixed"]) > 3:
            fixed += f" (+{len(entry['fixed']) - 3})"
        display_score = f"{entry['score']:g}" if entry["score"] else "—"
        print(f"| {name} | {cell(entry['severity'])} | {display_score} | "
              f"{len(entry['targets'])} | {cell(sorted(entry['targets'])[0])} | "
              f"{cell(packages)} | {cell(fixed)} |")
    if len(ordered) > 15:
        print(f"\nShowing 15 of {len(ordered)} unique IDs. Download the full JSON artifact for details.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: summarize_trivy.py REPORT.json")
    main(sys.argv[1])
