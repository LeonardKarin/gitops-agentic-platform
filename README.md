# gitops-agentic-platform

[![gitops-agentic-platform](https://img.shields.io/badge/gitops-agentic-platform-agentic-purple)]()
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue)]()
[![RGPD](https://img.shields.io/badge/RGPD-compliant-green)]()
[![FedRAMP](https://img.shields.io/badge/FedRAMP-aligned-green)]()
[![Languages](https://img.shields.io/badge/Languages-Python%20%7C%20Bash%20%7C%20Ansible%20%7C%20Perl-orange)]()

Shared Claude Code configuration layer for all your-org gitops-agentic-platform repositories.

```
github.com/your-org/saas/gitops-agentic-platform
branch : production (stable) · develop (staging)
tag    : gitops-agentic-platform-v<major>.<minor>
```

---

## Quick navigation

| I want to… | Go to |
|---|---|
| Set up a new machine | [Machine setup](#machine-setup) |
| Bootstrap a new consuming repo | [Repo bootstrap](#repo-bootstrap) |
| Onboard as a new developer on an existing repo | [New developer](#new-developer-on-an-existing-repo) |
| Understand the skill/rule/agent directory structure | [Directory structure](#directory-structure) |
| Know how rules are scoped | [How rules work](#how-rules-work) |
| Know how skills are deployed and why | [How skills work](#how-skills-work) |
| Know how agents are registered | [How agents work](#how-agents-work) |
| Use Claude Code daily | [Daily workflow](#daily-workflow) |
| Understand the audit trail | [Audit trail](#audit-trail) |
| Run security agents outside the REPL | [Running agents out of REPL](#running-agents-out-of-repl) |
| Use unsafe mode (no permission prompts) | [Unsafe mode](#unsafe-mode) |
| Update the shared layer | [Updating](#updating-the-shared-layer) |
| Understand compliance coverage | [Compliance](#compliance) |
| See the CI pipeline | [CI pipeline](#ci-pipeline) |

---

## Why real files, not symlinks

Claude Code v2.x scans `.claude/skills/` and `.claude/agents/` using an internal
file scanner that **does not follow symlinks**. Symlinked files are invisible to
`/skills` and `/agents`. All deployed files must be real copies.

`bootstrap.sh` copies — it does not create symlinks.

---

## Directory structure

### Repository layout (`/opt/git/gitops-agentic-platform`)

```
gitops-agentic-platform/
├── CLAUDE.md
├── README.md
├── bootstrap.sh                       # consuming repo setup script
├── run-agent.sh                       # agent invocation wrapper
├── .github/workflows/ci.yml
├── .editorconfig
├── .githooks/
│   └── post-commit                    # audit trail writer
└── .claude/
    ├── rules/
    │   ├── global-standards.md
    │   ├── bash-standards.md
    │   ├── python-standards.md
    │   ├── ansible-standards.md
    │   └── perl-standards.md
    ├── skills/
    │   ├── global-standards/
    │   │   └── SKILL.md
    │   ├── bash-standards/
    │   │   └── SKILL.md
    │   ├── python-standards/
    │   │   └── SKILL.md
    │   ├── ansible-standards/
    │   │   └── SKILL.md
    │   └── perl-standards/
    │       └── SKILL.md
    ├── agents/
    │   ├── security/
    │   │   ├── secrets-detection.md
    │   │   ├── vulnerability-scan.md
    │   │   ├── malware-scan.md
    │   │   ├── rootkit-detection.md
    │   │   ├── dependency-vulnerability-audit.md
    │   │   ├── supply-chain-risk.md
    │   │   ├── privilege-escalation-risk.md
    │   │   └── unsafe-tempfile-usage.md
    │   ├── audit/
    │   │   ├── session-audit.md
    │   │   ├── change-impact-assessment.md
    │   │   ├── backward-compatibility-check.md
    │   │   └── runtime-risk-estimation.md
    │   ├── quality/
    │   │   ├── refactor-safety-check.md
    │   │   ├── dead-code-detection.md
    │   │   ├── complexity-hotspot-detection.md
    │   │   ├── logging-consistency.md
    │   │   ├── docstring-quality.md
    │   │   ├── cli-ux-consistency.md
    │   │   ├── interface-contract-check.md
    │   │   └── layering-violation-check.md
    │   ├── infra/
    │   │   ├── ansible-idempotency-check.md
    │   │   ├── bash-strict-mode-check.md
    │   │   ├── config-drift-detection.md
    │   │   ├── repo-structure-check.md
    │   │   └── hardcoded-path-risk.md
    │   ├── workflow/
    │   │   └── checkpoint.md
    │   └── INVOCATION.md
    └── audit/
        └── .gitkeep
```

### How bootstrap.sh deploys skills (Claude Code v2.x requirement)

Claude Code v2.x requires skills to be named exactly `SKILL.md` and placed inside
a named subdirectory. Flat files like `SKILL-bash.md` are **not recognized**.

`bootstrap.sh` reads the source `SKILL-*.md` files from the repo and deploys them
to `$HOME/.claude/skills/<name>/SKILL.md`:

```
$HOME/.claude/skills/
├── global-standards/
│   └── SKILL.md        ← deployed from global standards source
├── bash-standards/
│   └── SKILL.md        ← deployed from bash standards source
├── python-standards/
│   └── SKILL.md        ← deployed from python standards source
├── ansible-standards/
│   └── SKILL.md        ← deployed from ansible standards source
└── perl-standards/
    └── SKILL.md        ← deployed from perl standards source
```

Skills are deployed to `$HOME/.claude/skills/` — not to the project-level
`.claude/skills/`. Claude Code reads from `$HOME` regardless of the working
directory. When running as root, `$HOME=/root`, so skills land in
`/root/.claude/skills/`.

### How bootstrap.sh deploys agents

Agents are deployed as real `.md` files to both the project-level `.claude/agents/`
and `$HOME/.claude/agents/`. The shared layer now supports categorized agent folders
(`security/`, `audit/`, `quality/`, `infra/`, `workflow/`). `run-agent.sh` resolves
agent files recursively by basename, so operators still invoke them as `bash run-agent.sh <agent>`.

```
$HOME/.claude/agents/
├── security/
│   ├── secrets-detection.md
│   ├── vulnerability-scan.md
│   ├── malware-scan.md
│   ├── rootkit-detection.md
│   ├── dependency-vulnerability-audit.md
│   ├── supply-chain-risk.md
│   ├── privilege-escalation-risk.md
│   └── unsafe-tempfile-usage.md
├── audit/
│   ├── session-audit.md
│   ├── change-impact-assessment.md
│   ├── backward-compatibility-check.md
│   └── runtime-risk-estimation.md
├── quality/
│   ├── refactor-safety-check.md
│   ├── dead-code-detection.md
│   ├── complexity-hotspot-detection.md
│   ├── logging-consistency.md
│   ├── docstring-quality.md
│   ├── cli-ux-consistency.md
│   ├── interface-contract-check.md
│   └── layering-violation-check.md
├── infra/
│   ├── ansible-idempotency-check.md
│   ├── bash-strict-mode-check.md
│   ├── config-drift-detection.md
│   ├── repo-structure-check.md
│   └── hardcoded-path-risk.md
├── workflow/
│   └── checkpoint.md
└── INVOCATION.md
```

### Consuming repo layout after bootstrap

```
<consuming-repo>/
├── CLAUDE.md                          # project-specific knowledge
├── run-agent.sh                       # symlink → /opt/git/gitops-agentic-platform/run-agent.sh
├── .gitignore                         # patched with runtime exclusions
├── .githooks/
│   └── post-commit                    # audit trail writer (copy, not symlink)
└── .claude/
    ├── rules/                         # project-level path-scoped rules
    │   ├── global-standards.md
    │   ├── bash-standards.md
    │   ├── python-standards.md
    │   ├── ansible-standards.md
    │   └── perl-standards.md
    ├── skills/                        # flat copies for reference — not scanned by Claude Code
    │   ├── SKILL-global.md
    │   ├── SKILL-bash.md
    │   ├── SKILL-python.md
    │   ├── SKILL-ansible.md
    │   └── SKILL-perl.md
    ├── agents/                        # real files — scanned by Claude Code
    │   ├── security/
    │   ├── audit/
    │   ├── quality/
    │   ├── infra/
    │   ├── workflow/
    │   └── INVOCATION.md
    └── audit/
        └── .gitkeep
```

---


---

## How rules work

Rules are path-scoped Markdown instructions stored in `.claude/rules/`. They complement
skills: rules define always-on repository policy by file type, while skills provide the
deeper reference context Claude loads for generation and review.

| Rule | Scope |
|---|---|
| `global-standards.md` | Every file — encoding, EOL, naming, cartridge, comment syntax |
| `bash-standards.md` | `.sh` — strict mode, quoting, shell-lib linkage, shellcheck |
| `python-standards.md` | `.py` — PEP 8, typing, FSM/aggregator patterns, logging safety |
| `ansible-standards.md` | `.yml` `.yaml` `.j2` — YAML 1.2.2, FQCN, inventory/campaign layout |
| `perl-standards.md` | `.pl` `.pm` — strict/warnings, lexical filehandles, argument discipline |

Rules are loaded from the project repository and are intended to be concise, deterministic,
and extension-scoped. Skills remain the richer reference layer.

## How skills work

Skills are plain Markdown files that Claude Code loads as context at session start.
They contain coding standards, conventions, and patterns that Claude applies
automatically to every response — no prompting required.

| Skill | Deployed as | Applies to |
|---|---|---|
| `SKILL-global.md` | `global-standards/SKILL.md` | Every file — encoding, EOL, Doxygen, cartridge, naming |
| `SKILL-bash.md` | `bash-standards/SKILL.md` | `.sh` files — strict mode, `##` blocks, shellcheck |
| `SKILL-python.md` | `python-standards/SKILL.md` | `.py` files — PEP 8, FSM patterns, secrets-vault |
| `SKILL-ansible.md` | `ansible-standards/SKILL.md` | `.yml` `.yaml` `.j2` — FQCN, YAML 1.2.2, campaigns |
| `SKILL-perl.md` | `perl-standards/SKILL.md` | `.pl` `.pm` — strict, warnings, safe file handling, explicit references |

Skills are visible in the REPL via `/skills` after bootstrap.

**Important**: skill files contain no YAML frontmatter, no Doxygen file headers,
no cartridge blocks. Pure instructional Markdown only — Claude reads them as
reference material, not as scripts.

---

## How agents work

Agents are Markdown runbooks with a YAML frontmatter block at the top. The
frontmatter registers them in Claude Code's `/agents` registry with a name,
description, model, and tool scope.

```yaml
---
name: secrets-detection
description: >
  Scans the repository for leaked API keys, passwords, SSH private keys...
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
---
```

The `description` field drives automatic invocation — Claude Code matches it
against the user's natural language prompt to decide which agent to delegate to.

| Agent | Model | Purpose |
|---|---|---|
| `secrets-detection` | Haiku | gitleaks repo secret scan |
| `vulnerability-scan` | Haiku | trivy Ubuntu CVE + secret scan |
| `malware-scan` | Haiku | clamscan virus/ransomware scan |
| `rootkit-detection` | Haiku | rkhunter rootkit + misconfiguration |
| `dependency-vulnerability-audit` | Haiku | dependency vulnerability and staleness review |
| `supply-chain-risk` | Haiku | curl-bash, unverified download, floating ref audit |
| `privilege-escalation-risk` | Haiku | sudo/chmod/become misuse review |
| `unsafe-tempfile-usage` | Haiku | /tmp race and insecure tempfile detection |
| `refactor-safety-check` | Haiku | interface/behavior drift check on changes |
| `dead-code-detection` | Haiku | stale helper and unused code detection |
| `complexity-hotspot-detection` | Haiku | maintainability hotspot detection |
| `ansible-idempotency-check` | Haiku | repeated-run safety and idempotency review |
| `bash-strict-mode-check` | Haiku | strict mode, quoting, trap and shell safety review |
| `logging-consistency` | Haiku | timestamp/severity/log hygiene review |
| `config-drift-detection` | Haiku | duplicated/conflicting config source review |
| `repo-structure-check` | Haiku | repository layout and placement hygiene review |
| `layering-violation-check` | Haiku | architecture boundary / layering review |
| `interface-contract-check` | Haiku | internal API and contract stability review |
| `change-impact-assessment` | Haiku | blast radius and affected workflow assessment |
| `backward-compatibility-check` | Haiku | compatibility break risk review |
| `runtime-risk-estimation` | Haiku | production execution risk estimate |
| `docstring-quality` | Haiku | docstring and structured comment quality review |
| `cli-ux-consistency` | Haiku | operator UX and CLI consistency review |
| `session-audit` | Haiku | session close + audit summary writer |
| `checkpoint` | Sonnet | pre-push confirmation gate |

Agents are visible in the REPL via `/agents` after bootstrap.

---

## Machine setup

Run once per developer workstation and CI runner:

```bash
sudo git clone git@github.com/your-org:saas/gitops-agentic-platform.git \
  /opt/git/gitops-agentic-platform

cd /opt/git/gitops-agentic-platform && sudo git checkout production
```

This follows the existing convention: `/opt/git/nas/`, `/opt/git/rundeck/`,
`/opt/git/nagios/`, `/opt/git/noovem/`.

---

## Repo bootstrap

Run once from the consuming repo root:

```bash
bash /opt/git/gitops-agentic-platform/bootstrap.sh
```

The script performs these steps in order:

| Step | What it does |
|---|---|
| Preflight | Verifies shared layer exists, not running inside gitops-agentic-platform itself |
| Skills | Copies `SKILL-*.md` to project `.claude/skills/` (flat, for reference) |
| Skills HOME | Deploys `$HOME/.claude/skills/<name>/SKILL.md` (Claude Code scanner target) |
| Agents | Copies agent `.md` files to project `.claude/agents/` and `$HOME/.claude/agents/` |
| Repo root | Copies `run-agent.sh` to repo root |
| Git hook | Copies `.githooks/post-commit`, sets `core.hooksPath` |
| Audit dir | Creates `.claude/audit/` with `.gitkeep` |
| `.gitignore` | Appends runtime exclusions |
| `CLAUDE.md` | Appends shared-layer reference block |

Then commit:

```bash
git add -A
git commit -m "chore: add gitops-agentic-platform shared layer ($(cd /opt/git/gitops-agentic-platform && git describe))"
git push origin <branch>
```

---

## New developer on an existing repo

```bash
# 1. machine setup (once)
sudo git clone git@github.com/your-org:saas/gitops-agentic-platform.git /opt/git/gitops-agentic-platform

# 2. clone the consuming repo
git clone git@github.com/your-org:saas/<repo>.git && cd <repo>

# 3. deploy skills and agents to $HOME (bootstrap handles this)
bash /opt/git/gitops-agentic-platform/bootstrap.sh

# 4. activate git hook for this clone
git config core.hooksPath .githooks

# 5. open Claude Code
claude .
```

Note: `core.hooksPath` lives in `.git/config` — not committed. Every fresh clone
must run step 4 once to activate the post-commit audit hook.

---

## Updating the shared layer

```bash
cd /opt/git/gitops-agentic-platform && sudo git pull origin production

# re-run bootstrap to redeploy updated skills and agents
cd <consuming-repo>
bash /opt/git/gitops-agentic-platform/bootstrap.sh
```

Check active version:

```bash
cd /opt/git/gitops-agentic-platform && git describe
```

---

## Daily workflow

### Login (first time on a new machine)

```bash
claude /login
```

### Open Claude Code

```bash
claude .
# or in unsafe mode — all tool calls auto-approved
claude --dangerously-skip-permissions .
```

### Work via natural language

Claude applies skill standards silently on every response. No prompting required.

```
Create a new Ansible campaign called nginx-hardening that enforces TLS 1.2
on prod_enterprise hosts. Playbook, tasks file, and vars file.
```

### Invoke agents by intent

```
check the repo for leaked secrets
run a vulnerability scan
scan for viruses
check for rootkits
audit supply-chain risk
check ansible idempotency
review bash strict mode
estimate runtime risk
assess change impact
close session
push to production
```

Claude matches intent to the correct agent from `/agents` context and executes it.

---

## Audit trail

The post-commit hook reads the Claude session transcript after every `git commit`
and writes structured log entries to `.claude/audit/` automatically.

### Session transcript location

```
~/.claude/projects/<path-hash>/<session-uuid>.jsonl
```

Path hash derivation:

```bash
pwd | sed 's|/|-|g' | sed 's|^-||'
# /home/dev/rundeck-dev → home-dev-rundeck-dev
```

### What the hook does

After every `git commit` the hook:
1. Locates the most recent `.jsonl` for this repo
2. Extracts all exchanges since the previous commit timestamp
3. Sanitizes credential patterns (redacts base64 blobs, PEM headers, `password=` etc.)
4. Writes one `request-<n>-<slug>.log` per exchange
5. Appends to `session-<epoch>.log`
6. Updates `index.json`

CI commits (`[cartridge]`, `[update cycle]`) are detected and skipped.

### Audit entry format

```
REQUEST #001
timestamp   : 2025-06-03T09:10:02.341Z
source      : claude-session-transcript (post-commit hook)
commit      : a3f9b2c
type        : create-or-modify
classif     : INTERNAL

prompt      : "Create a new Ansible campaign called nginx-hardening…"
assistant   : "Done. 3 files created under ansible/playbooks/nginx-hardening/…"

tools       :
  Read: {"file_path": ".claude/skills/SKILL-ansible.md"}
  Write: {"file_path": "ansible/playbooks/nginx-hardening/nginx-hardening.yaml"}

files       :
  written: ansible/playbooks/nginx-hardening/nginx-hardening.yaml (INTERNAL)

compliance  :
  source    : claude session transcript — guaranteed by git hook
  fedramp   : CM-3
  sanitized : credential patterns redacted
```

---

## Running agents out of REPL

`run-agent.sh` now resolves agent files recursively under `.claude/agents/`, so
folder organization does not change operator commands.


For CI pipelines or a second terminal while the REPL is busy:

```bash
# unsafe mode — no confirmation prompts (default)
bash run-agent.sh secrets-detection
bash run-agent.sh vulnerability-scan
bash run-agent.sh malware-scan
bash run-agent.sh rootkit-detection
bash run-agent.sh session-audit
bash run-agent.sh checkpoint

# safe mode — prompts on sensitive tool calls
bash run-agent.sh secrets-detection safe
```

Each security agent performs a CVE pre-check before installing its tool:

```
NVD → CISA KEV → OSV → Ubuntu Security → EPSS scoring
```

Installation blocked on: CVSS ≥ 7.0 · CISA KEV match · EPSS ≥ 0.7

---

## Unsafe mode

| Context | Command |
|---|---|
| REPL session | `claude --dangerously-skip-permissions .` |
| Agent via wrapper | `bash run-agent.sh <agent>` (unsafe by default) |
| Agent safe mode | `bash run-agent.sh <agent> safe` |
| Direct invocation | `claude -p "$(cat .claude/agents/<agent>.md)" --dangerously-skip-permissions` |

`--dangerously-skip-permissions` auto-approves every bash command, file read, and
file write. Acceptable for these agents because their runbooks are versioned in
`gitops-agentic-platform` and reviewed via MR. Never use with arbitrary unreviewed prompts.

---

## Compliance

All files in this repository are **INTERNAL** classification.

Runtime security agent outputs are **CONFIDENTIAL** — never commit:

```
/tmp/gitleaks-report.json
/tmp/trivy-os-report.json
/tmp/trivy-secret-report.json
/tmp/clamscan-report.txt
/var/log/rkhunter.log
```

| FedRAMP control | Mechanism |
|---|---|
| `CM-3` | Every commit produces an audit entry traceable to an operator prompt |
| `CM-6` | Coding standards enforced at generation time via skill files |
| `AU-2` | All Claude Code actions captured in the session transcript |
| `AU-3` | Audit records contain timestamp, operator, action, files, outcome |
| `AU-9` | Audit logs committed to git — immutable, versioned |
| `IA-5` | secrets-detection scans for credential leaks before push |
| `SI-2` | vulnerability-scan tracks CVEs in installed packages |
| `SI-3` | malware-scan detects viruses and ransomware |
| `IR-4` | rootkit-detection identifies active compromise indicators |

---

## CI pipeline

| Stage | Job | Checks |
|---|---|---|
| `lint` | `shellcheck-lint` | `bootstrap.sh` · `run-agent.sh` · `.githooks/post-commit` |
| `validate` | `validate-skills` | Every `SKILL-*.md` has required content markers |
| `validate` | `validate-agents` | Every agent `.md` has YAML frontmatter + `Compliance Note` section |
| `validate` | `validate-editorconfig` | `.editorconfig` present, enforces `end_of_line = lf` |
| `cardridge` | `cardridge` | Injects `### S-GLCR ###` headers on managed scripts |
| `tag` | `tag` | Auto-increments `gitops-agentic-platform-v<major>.<minor>` on production push |