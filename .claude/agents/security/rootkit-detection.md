---
name: rootkit-detection
description: >
  Checks the local system for rootkits, backdoors, local exploits, and security
  misconfigurations using rkhunter. Invoke when the user asks for a rootkit scan,
  security misconfiguration check, or system integrity verification.
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
---

<!--
 * @file        rootkit-detection.md
 * @brief       Subagent definition — rootkit and security misconfiguration scan via rkhunter
 * @details     Non-interactive Claude Code subagent that checks for rootkits,
 *              backdoors, local exploits, and common security misconfigurations
 *              using rkhunter. Updates rkhunter database before each run.
 *              Installs rkhunter only if no open CVEs are found via the CVE
 *              pre-check pipeline defined below.
 * @author      Platform Engineering
 * @project     gitops-agentic-platform
 * @compliance  RGPD · FedRAMP — SI (System & Info Integrity) · CM (Config Mgmt)
-->

---

## Agent Identity

```yaml
name: rootkit-detection
description: >
  Checks the local system for rootkits, backdoors, local exploits, and
  security misconfigurations using rkhunter. Updates the rkhunter database
  before each run. Produces a structured log and a human-readable summary.
  All findings are classified CONFIDENTIAL.
model: claude-sonnet-4-6
permission_mode: auto
```

---

## Invocation

```bash
bash run-agent.sh rootkit-detection
# or directly:
claude -p "$(cat .claude/agents/rootkit-detection.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

---

## Scope

rkhunter checks performed:

| Check category | What it detects |
|---|---|
| Rootkit signatures | Known rootkit file and directory patterns |
| Backdoors | Network backdoor binaries and suspicious listeners |
| Local exploits | SUID/SGID files, world-writable paths, suspicious symlinks |
| System binaries | Hash comparison of standard system commands against baseline |
| Network interfaces | Promiscuous mode, unexpected listeners |
| Startup files | Suspicious entries in rc, init, and cron |
| SSH configuration | Weak SSH daemon settings (PermitRootLogin, Protocol) |
| File property changes | Modifications to system files since last baseline |
| Hidden files | Unusual hidden files in system paths |

---

## Pre-check: CVE Gating Before Installation

If `rkhunter` is not present, complete the CVE pre-check before installing.
Installation is blocked on CVSS ≥ 7.0 or CISA KEV match.

### CVE query pipeline

```
1. Target package: rkhunter (Ubuntu apt)

2. Query sources in order:

   PRIMARY:
     https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=rkhunter
     https://www.cve.org/api/?query=rkhunter

   EXPLOITED (always checked):
     https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json
     → filter: product contains "rkhunter"

   OPEN SOURCE:
     https://api.osv.dev/v1/query  body: {"package": {"name": "rkhunter", "ecosystem": "Ubuntu"}}
     https://api.github.com/advisories?query=rkhunter

   VENDOR:
     https://ubuntu.com/security/cves.json?q=rkhunter
     https://security-tracker.debian.org/tracker/source-package/rkhunter

   SCORING:
     https://api.first.org/data/v1/epss?cve={CVE-ID}

3. Decision:
   - CVSS base score ≥ 7.0  → BLOCK install, halt agent
   - CISA KEV match          → BLOCK install regardless of CVSS
   - EPSS ≥ 0.7              → BLOCK install
   - All clean               → proceed
```

### Installation (if CVE pre-check passes)

```bash
## @brief   Install rkhunter and initialize its system file property database

apt-get install -y rkhunter

# initialize baseline — must run before first scan
rkhunter --propupd --quiet

# update rootkit signature database
rkhunter --update --quiet || true  # --update returns 1 on "already up to date" — expected
```

---

## Execution

### Step 1 — Update database

```bash
## @brief   Refresh rkhunter rootkit signature and data files

rkhunter --update --quiet || true
```

### Step 2 — Run rkhunter scan

```bash
## @brief   Full system check for rootkits, backdoors, and misconfigurations
## @note    Report: /var/log/rkhunter.log (CONFIDENTIAL, root-owned)
## @note    Exit code: 0 = clean; 1 = warnings; 2 = error

rkhunter \
  --check \
  --skip-keypress \
  --report-warnings-only \
  --nocolors \
  --logfile /var/log/rkhunter.log \
  --quiet

_exit_code=$?
```

Flags:

| Flag | Purpose |
|---|---|
| `--check` | Run all enabled checks |
| `--skip-keypress` | Non-interactive mode — no user prompts |
| `--report-warnings-only` | Suppress passing checks — output only warnings and errors |
| `--nocolors` | Plain text output — safe for CI log capture |
| `--logfile` | Detailed log — classified CONFIDENTIAL, root-owned |

### SSH configuration check (supplementary)

```bash
## @brief   Verify SSH daemon configuration against security baseline
## @note    Checks align with FedRAMP IA-2 and CM-6 requirements

_sshd_config="/etc/ssh/sshd_config"

_check_ssh_setting() {
	local _key="${1}" _expected="${2}"
	local _actual
	_actual=$(sshd -T 2>/dev/null | grep -i "^${_key} " | awk '{print $2}')
	if [[ "${_actual,,}" != "${_expected,,}" ]]; then
		echo "WARNING: SSH ${_key} = '${_actual}' (expected: '${_expected}')"
	fi
}

_check_ssh_setting "PermitRootLogin"    "no"
_check_ssh_setting "Protocol"           "2"
_check_ssh_setting "PasswordAuthentication" "no"
_check_ssh_setting "PermitEmptyPasswords"   "no"
_check_ssh_setting "X11Forwarding"          "no"
_check_ssh_setting "MaxAuthTries"           "3"
```

---

## Output & Reporting

### 1. Full rkhunter log — `/var/log/rkhunter.log` (CONFIDENTIAL)

Detailed rkhunter output. Root-owned, mode 0600. Contains system path details that may expose
infrastructure topology — **do not copy or transmit outside the system**.

### 2. Human-readable summary (stdout)

```
ROOTKIT DETECTION REPORT
=========================
Scan timestamp    : <ISO 8601 UTC>
Host              : <hostname>
rkhunter version  : <version>
DB data file      : <date>

── CHECK SUMMARY ──────────────────────────────────────────────────────────────
Rootkits          : <N> warning(s)
Backdoors         : <N> warning(s)
Local exploits    : <N> warning(s)
System commands   : <N> file property warning(s)
SSH config        : <N> misconfiguration(s)
Network           : <N> warning(s)
Startup files     : <N> warning(s)

[WARNING 1]  (if any)
  Check         : System binary file properties
  File          : /usr/bin/wget
  Detail        : MD5 hash mismatch — expected <hash>, got <hash>
  Severity      : HIGH

[WARNING 2]
  Check         : SSH configuration
  Setting       : PermitRootLogin
  Value         : yes
  Expected      : no
  Severity      : HIGH

[COMPLIANCE NOTE]
  Classification  : CONFIDENTIAL
  RGPD impact     : Rootkit on a data-processing node constitutes a personal data
                    breach — Art. 33/34 GDPR notification assessment required
  FedRAMP families: SI-3 (Malicious Code), CM-6 (Configuration Settings),
                    CM-7 (Least Functionality), IA-2 (Identification & Auth)

Recommended actions:
  1. Hash mismatch on system binary → verify with dpkg: dpkg --verify <package>
  2. PermitRootLogin yes → set to "no" in /etc/ssh/sshd_config; systemctl restart sshd
  3. Any confirmed rootkit → isolate node, escalate to Incident Response immediately
  4. Open a formal CM-3 change ticket for any configuration remediation
  5. Re-run scan after remediation to confirm clean state
```

### Exit code handling

```bash
case "${_exit_code}" in
  0) echo "RESULT: CLEAN — no warnings detected" ;;
  1) echo "RESULT: WARNINGS — review /var/log/rkhunter.log"; exit 1 ;;
  2) echo "RESULT: ERROR — rkhunter did not complete cleanly"; exit 2 ;;
esac
```

---

## Baseline Maintenance

The rkhunter property database (`--propupd`) must be updated after every intentional system
change (package upgrades, new binary deployments) to prevent false positives on the next scan.

```bash
## @brief   Update rkhunter baseline after intentional system changes
## @warning Only run after a verified, clean system change — never to suppress a true finding

rkhunter --propupd --quiet
```

This update must be triggered via **Rundeck** after any Ansible campaign that modifies system
binaries — add it as a post-task in the campaign playbook via the appropriate Rundeck job call.

---

## Compliance Note

**RGPD**: A rootkit finding on any node that processes personal data must be immediately escalated
as a potential data breach. The controller has 72 hours to notify the supervisory authority
(Art. 33 GDPR) if the breach is likely to result in a risk to natural persons.

**FedRAMP**: Maps to control families:
- `SI-3` — Malicious Code Protection
- `CM-6` — Configuration Settings (SSH hardening)
- `CM-7` — Least Functionality (disable unnecessary services)
- `IA-2` — Identification and Authentication (no root SSH)
- `IR-4` — Incident Handling (rootkit = security incident)
- `CA-7` — Continuous Monitoring (periodic rkhunter baseline comparison)