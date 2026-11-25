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
        return "ignored: account identifier"
    if WORDLIST_PATH.search(target):
        return "ignored: wordlist"
    if target.startswith("/home/hacker/.nuclei-templates/"):
        return "ignored: public examples"
    if target.startswith(("/opt/metasploit/spec/", "/opt/exploitdb/exploits/", "/opt/phpggc/gadgetchains/")):
        return "ignored: public examples"
    if FASTHTTP_TEST_KEY.fullmatch(target) or GO_TEST_KEY.fullmatch(target):
        return "ignored: public examples"
    if (rule == "azure-storage-account-key"
            and target == "/home/hacker/.vscode/extensions/ms-azuretools.vscode-containers-2.5.3/dist/extension.bundle.js"
            and "devstoreaccount1" in secret.get("Match", "")):
        return "ignored: documented placeholder"
    if target.startswith(("/opt/metasploit/data/exploits/", "/opt/metasploit/modules/")):
        return "ignored: upstream key material"
    if UV_UPSTREAM_SOURCE.fullmatch(target):
        return "ignored: upstream key material"
    if target in ("/opt/HExHTTP/build/lib/modules/technos/cloudflare.py",
                  "/opt/HExHTTP/modules/technos/cloudflare.py"):
        return "ignored: upstream key material"
    return "unreviewed"


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
    total = 0
    for result in report.get("Results") or []:
        target = result.get("Target") or "unknown target"
        for secret in result.get("Secrets") or []:
            total += 1
            rule = secret.get("RuleID") or "unknown rule"
            line = secret.get("StartLine") or "—"
            key = (rule, target, line)
            severity = secret.get("Severity") or "UNKNOWN"
            decision = image_triage(target, secret) if args.triage_image else "unreviewed"
            previous = findings.get(key)
            if previous is None or SEVERITY_RANK.get(severity, 0) > SEVERITY_RANK.get(previous[0], 0):
                findings[key] = (severity, decision)

    ordered = sorted(findings.items(), key=lambda item: (
        -SEVERITY_RANK.get(item[1][0], 0), item[0][0], item[0][1], str(item[0][2])
    ))
    print(f"## Trivy secrets: {cell(args.scope)}\n")
    if args.triage_image:
        ordered = [item for item in ordered if item[1][1] == "unreviewed"]
        print(f"**{len(ordered)} unreviewed secret findings.**\n")
    else:
        counts = Counter(severity for severity, _ in findings.values())
        print(f"**{total} matches in {len(findings)} distinct locations** "
              f"({counts['CRITICAL']} critical, {counts['HIGH']} high, "
              f"{counts['MEDIUM']} medium, {counts['LOW']} low).\n")
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
