#!/usr/bin/env python3
"""Summarize Trivy secret findings without exposing matched content."""

import argparse
import json
import re
from collections import Counter
from pathlib import Path


SEVERITY_RANK = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "LOW": 1}
WORDLIST_PATH = re.compile(r"(^|/)(?:wordlists?|lists)(/|$)", re.I)
FASTHTTP_TEST_KEY = re.compile(
    r"^/home/hacker/\.local/go/pkg/mod/github\.com/valyala/fasthttp@[^/]+/fasthttputil/(?:ecdsa|rsa)\.key$"
)
GO_TEST_KEY = re.compile(
    r"^/home/hacker/\.local/share/mise/installs/go/[^/]+/src/crypto/x509/platform_root_key\.pem$"
)
UV_UPSTREAM_SOURCE = re.compile(
    r"^/home/hacker/\.cache/uv/archive-v0/[^/]+/(?:yt_dlp/extractor/.*|sqlmap/lib/utils/jwt\.py|modules/technos/cloudflare\.py)$"
)


def image_triage(target, secret):
    """Classify verified public data; leave new locations visible for review."""
    rule = secret.get("RuleID")
    if rule == "aws-account-id":
        return "ignored: account identifier", "AWS account ID"
    if WORDLIST_PATH.search(target):
        return "ignored: wordlist", "Bundled wordlists"
    if target.startswith("/home/hacker/.nuclei-templates/"):
        return "ignored: public examples", "Nuclei templates and payloads"
    if target.startswith(("/opt/metasploit/spec/", "/opt/exploitdb/exploits/", "/opt/phpggc/gadgetchains/")):
        return "ignored: public examples", "Upstream tests and exploit examples"
    if FASTHTTP_TEST_KEY.fullmatch(target) or GO_TEST_KEY.fullmatch(target):
        return "ignored: public examples", "Upstream test keys"
    if (rule == "azure-storage-account-key"
            and target == "/home/hacker/.vscode/extensions/ms-azuretools.vscode-containers-2.5.3/dist/extension.bundle.js"
            and "devstoreaccount1" in secret.get("Match", "")):
        return "ignored: documented placeholder", "Azurite emulator key"
    if target.startswith(("/opt/metasploit/data/exploits/", "/opt/metasploit/modules/")):
        return "reviewed: upstream key material", "Metasploit exploit material"
    if UV_UPSTREAM_SOURCE.fullmatch(target):
        if target.endswith("/yt_dlp/extractor/shahid.py"):
            return "reviewed: upstream key material", "yt-dlp Shahid extractor"
        return "reviewed: upstream key material", "Installed third-party package source"
    if target in ("/opt/HExHTTP/build/lib/modules/technos/cloudflare.py",
                  "/opt/HExHTTP/modules/technos/cloudflare.py"):
        return "reviewed: upstream key material", "HExHTTP upstream source"
    return "unreviewed", "New location"


def cell(value):
    return str(value or "—").replace("|", "\\|").replace("\n", " ").replace("\r", " ")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("scope")
    parser.add_argument("--fail-on-findings", action="store_true")
    parser.add_argument("--triage-image", action="store_true")
    args = parser.parse_args()

    report = json.loads(args.report.read_text())
    findings = {}
    decisions = Counter()
    reviewed = Counter()
    reviewed_targets = {}
    total = 0
    for result in report.get("Results") or []:
        target = result.get("Target") or "unknown target"
        for secret in result.get("Secrets") or []:
            total += 1
            rule = secret.get("RuleID") or "unknown rule"
            line = secret.get("StartLine") or "—"
            key = (rule, target, line)
            severity = secret.get("Severity") or "UNKNOWN"
            decision, source = image_triage(target, secret) if args.triage_image else ("unreviewed", "")
            previous = findings.get(key)
            if previous is None or SEVERITY_RANK.get(severity, 0) > SEVERITY_RANK.get(previous[0], 0):
                findings[key] = (severity, decision)
            if args.triage_image:
                decisions[decision] += 1
                if decision == "reviewed: upstream key material":
                    review_key = (severity, rule, source)
                    reviewed[review_key] += 1
                    reviewed_targets.setdefault(review_key, set()).add(target)

    ordered = sorted(findings.items(), key=lambda item: (
        -SEVERITY_RANK.get(item[1][0], 0), item[0][0], item[0][1], str(item[0][2])
    ))
    counts = Counter(severity for severity, _ in findings.values())
    print(f"## Trivy secrets: {cell(args.scope)}\n")
    print(f"**{total} matches in {len(findings)} distinct locations** "
          f"({counts['CRITICAL']} critical, {counts['HIGH']} high, "
          f"{counts['MEDIUM']} medium, {counts['LOW']} low).\n")
    if args.triage_image:
        print("| Triage | Matches |")
        print("| --- | ---: |")
        for decision, count in sorted(decisions.items()):
            print(f"| {cell(decision)} | {count} |")
        print("\nKnown public examples and wordlists are excluded from the active finding list. "
              "Reviewed upstream key material remains visible below; some keys are real public "
              "vendor defaults or embedded tool credentials, not SkillArch-owned secrets.\n")
        if reviewed:
            print("| Reviewed upstream source | Severity | Rule | Matches | Example target |")
            print("| --- | --- | --- | ---: | --- |")
            for (severity, rule, source), count in sorted(reviewed.items(), key=lambda item: (
                    -SEVERITY_RANK.get(item[0][0], 0), item[0][2], item[0][1])):
                example = sorted(reviewed_targets[(severity, rule, source)])[0]
                print(f"| {cell(source)} | {cell(severity)} | {cell(rule)} | {count} | {cell(example)} |")
            print()
        ordered = [item for item in ordered if item[1][1] == "unreviewed"]
        print(f"**{len(ordered)} unreviewed locations** remain.\n")
    if ordered:
        print("Matched values and source snippets are omitted from CI logs. "
              "Run Trivy locally to inspect a finding.\n")
        print("| Severity | Rule | Target | Line |")
        print("| --- | --- | --- | ---: |")
        for (rule, target, line), (severity, _) in ordered[:20]:
            print(f"| {cell(severity)} | {cell(rule)} | {cell(target)} | {cell(line)} |")
        if len(ordered) > 20:
            print(f"\nShowing 20 of {len(ordered)} locations.")
    if args.fail_on_findings and total:
        raise SystemExit(1)
    if args.triage_image and any(severity in ("HIGH", "CRITICAL") for _, (severity, _) in ordered):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
