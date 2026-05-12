---
name: secrets-detection
description: >
  Scans the repository for leaked API keys, passwords, SSH private keys, and any
  credential material in git history or the working tree. Invoke when the user asks
  to check for secrets, scan for credentials, or before any push to production.
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
---

<!--
 * @file        secrets-detection.md
 * @brief       Subagent definition — repository secret leak detection via gitleaks
 * @details     Non-interactive Claude Code subagent that scans the repository for
 *              leaked API keys, passwords, SSH private keys, and other credentials.
 *              Runs gitleaks against the full git history and working tree.
 *              Installs gitleaks only if no open CVEs are found via the CVE
 *              pre-check pipeline defined below.
 * @author      Platform Engineering
 * @project     gitops-agentic-platform
 * @compliance  RGPD · FedRAMP — AU (Audit) · IA (Identification & Authentication)
-->

---

## Agent Identity

```yaml
name: secrets-detection
description: >
  Scans the repository for leaked API keys, passwords, SSH private keys,
  and any credential material committed to git history or the working tree.
  Uses gitleaks. Produces a structured JSON report and a human-readable
  summary. Classifies all findings as CONFIDENTIAL.
model: claude-sonnet-4-6
permission_mode: auto
```

---

## Invocation

```bash
bash run-agent.sh secrets-detection
# or directly:
claude -p "$(cat .claude/agents/secrets-detection.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

---

## Scope

- Full git history: all branches reachable from HEAD
- Working tree: all tracked and untracked files in the repository root
- Home directory credential files: `~/.ssh/`, `~/.aws/`, `~/.netrc`, `~/.pgpass`

Explicitly excluded from scan (noise suppression):

```
static/           # aggregator output — already Git-excluded
.claude/vault/         # vault credentials — already Git-excluded, expected to be absent
```

---

## Pre-check: CVE Gating Before Installation

If `gitleaks` is not present on the system, the agent **must** complete the following CVE
pre-check before installing. Installation is blocked if any open CVE with CVSS ≥ 7.0 or any
CISA Known Exploited Vulnerability (KEV) entry is found for the target version.

### CVE query pipeline

```
1. Resolve latest stable release tag from:
   https://api.github.com/repos/gitleaks/gitleaks/releases/latest

2. Query each source in order — stop at first confirmed clean result:

   PRIMARY:
     https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=gitleaks
     https://www.cve.org/api/?query=gitleaks

   EXPLOITED (always checked regardless of PRIMARY result):
     https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json
     → filter: vendorProject == "gitleaks" OR product contains "gitleaks"

   OPEN SOURCE:
     https://api.osv.dev/v1/query  body: {"package": {"name": "gitleaks", "ecosystem": "Go"}}
     https://api.github.com/advisories?query=gitleaks

   VENDOR:
     https://ubuntu.com/security/cves.json?q=gitleaks

   SCORING (for each CVE-ID found above):
     https://api.first.org/data/v1/epss?cve={CVE-ID}

3. Decision:
   - Any CVE with CVSS base score ≥ 7.0 → BLOCK install, report finding, halt agent
   - Any entry in CISA KEV feed → BLOCK install regardless of CVSS score
   - EPSS score ≥ 0.7 (70th percentile exploitation probability) → BLOCK install
   - All checks clean → proceed with installation
```

### Installation (if CVE pre-check passes)

```bash
## @brief   Install gitleaks from GitHub releases (verified binary)
## @note    SHA256 checksum must match the release manifest before execution

_version=$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")

_arch=$(uname -m)
case "${_arch}" in
  x86_64)  _arch_tag="x64"   ;;
  aarch64) _arch_tag="arm64" ;;
  *)       echo "Unsupported arch: ${_arch}"; exit 1 ;;
esac

_tarball="gitleaks_${_version#v}_linux_${_arch_tag}.tar.gz"
_url="https://github.com/gitleaks/gitleaks/releases/download/${_version}/${_tarball}"
_checksums_url="https://github.com/gitleaks/gitleaks/releases/download/${_version}/gitleaks_${_version#v}_checksums.txt"

curl -fsSL "${_url}" -o "/tmp/${_tarball}"
curl -fsSL "${_checksums_url}" -o "/tmp/checksums.txt"

# verify checksum before execution
cd /tmp && grep "${_tarball}" checksums.txt | sha256sum --check --strict

tar -xzf "/tmp/${_tarball}" -C /usr/local/bin/ gitleaks
chmod 0755 /usr/local/bin/gitleaks
```

---

## Execution

```bash
## @brief   Run gitleaks against full git history and working tree
## @note    Report written to /tmp/gitleaks-report.json (CONFIDENTIAL)

gitleaks detect \
  --source . \
  --report-format json \
  --report-path /tmp/gitleaks-report.json \
  --redact \
  --no-banner \
  --exit-code 1
```

Flags:

| Flag | Purpose |
|---|---|
| `--source .` | Scan current directory (git repo root) |
| `--report-format json` | Machine-readable output for downstream processing |
| `--report-path` | Persist report — classified CONFIDENTIAL |
| `--redact` | Replace secret values with `REDACTED` in report output |
| `--no-banner` | Suppress version banner (clean CI output) |
| `--exit-code 1` | Non-zero exit on any finding — fails CI gate |

---

## Output & Reporting

The agent produces two outputs:

### 1. JSON report — `/tmp/gitleaks-report.json` (CONFIDENTIAL)

Raw gitleaks JSON output with redacted secret values. Contains: rule ID, file path, commit hash,
author, date, line number, match description.

**Do not log this file to stdout or commit it to git.**

### 2. Human-readable summary (stdout — INTERNAL)

The agent prints a structured summary to stdout after the scan:

```
SECRETS DETECTION REPORT
========================
Scan timestamp : <ISO 8601 UTC>
Repository     : <git remote origin URL>
Head commit    : <hash>
Branches       : <count> scanned

Findings       : <N> secret(s) detected

[FINDING 1]
  Rule         : generic-api-key
  File         : ansible/playbooks/deploy/vars.yaml
  Commit       : a3f9b2c1
  Author       : jdoe
  Date         : 2024-11-03
  Line         : 42
  Description  : Generic API key pattern matched
  Secret       : REDACTED

[COMPLIANCE NOTE]
  Classification : CONFIDENTIAL
  RGPD impact    : Potential credential exposure — review and rotate immediately
  FedRAMP family : IA-5 (Authenticator Management), AU-9 (Protection of Audit Information)

Recommended actions:
  1. Rotate all detected credentials immediately
  2. Rewrite git history to remove secrets: git filter-repo --path <file> --invert-paths
  3. Review access logs for the exposed credential since <date>
  4. File an incident report per the FedRAMP IR control family
```

---

## Compliance Note

**RGPD**: Secret detection findings may reveal credentials that provide access to personal data
stores. Any finding must be treated as a potential personal data breach until the credential's
access scope is confirmed.

**FedRAMP**: Maps to control families:
- `IA-5` — Authenticator Management (credential rotation)
- `AU-9` — Protection of Audit Information
- `CM-3` — Configuration Change Control (history rewrite requires formal change)
- `IR-6` — Incident Reporting (mandatory if credentials accessed external systems)