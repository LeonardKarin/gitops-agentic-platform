---
name: checkpoint
description: >
  Pre-push confirmation gate. Presents a structured summary of all session demands,
  files changed, classification, compliance flags, linting status, and proposed git
  commands before executing any push to main or production. Always invoke before
  pushing to a protected branch.
model: claude-sonnet-4-6
tools:
  - Bash
  - Read
  - Write
---

<!--
 * @file        checkpoint.md
 * @brief       Subagent definition — pre-push confirmation gate
 * @details     Defines the mandatory checkpoint procedure that Claude Code must execute
 *              before any push to the main or production git branch. Triggered by
 *              an explicit CLI prompt from the user. Claude summarizes session demands,
 *              lists all changes, assesses compliance impact, and requests confirmation
 *              before proceeding.
 * @author      Platform Engineering
 * @project     gitops-agentic-platform
 * @compliance  RGPD · FedRAMP — CM (Configuration Management) · AU (Audit)
-->

---

## Purpose

Before any push to `main` or `production`, Claude Code must pause and present a structured
checkpoint to the operator. The checkpoint ensures:

1. The operator is aware of **every change** made during the session
2. **Compliance risks** are surfaced before they reach a protected branch
3. A **summary of user demands** is recorded for audit purposes
4. Explicit **human confirmation** is required before git push proceeds

This checkpoint is a FedRAMP CM-3 (Configuration Change Control) gate and a RGPD accountability
measure. It must never be bypassed, abbreviated, or auto-confirmed.

---

## Trigger Conditions

The checkpoint activates when the operator issues any of the following (or semantically equivalent)
prompts via the Claude Code CLI:

```
push to main
push to production
merge to main
merge to production
deploy to production
tag and push
release
```

It also activates automatically if Claude Code detects that a proposed `git push` targets a
branch named `main`, `production`, `prod`, or `release/*`.

---

## Checkpoint Format

Claude Code must render the following checkpoint before executing any push. All sections are
mandatory. Omitting any section is a compliance violation.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                        CLAUDE CODE — PRE-PUSH CHECKPOINT                   ║
║                        Branch: <branch>  |  <ISO 8601 UTC>                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

── 1. SESSION DEMANDS SUMMARY ─────────────────────────────────────────────────

The following requests were made by the operator during this session:

  [1] <concise one-line summary of demand #1>
  [2] <concise one-line summary of demand #2>
  ...

── 2. FILES MODIFIED / CREATED / DELETED ──────────────────────────────────────

  MODIFIED:
    ansible/playbooks/openssh/openssh_CVE-2024-6387.yaml
    py-netbox-plw/netbox_api.py

  CREATED:
    .claude/agents/secrets-detection.md
    .claude/skills/SKILL-bash.md

  DELETED:
    (none)

  Total: <N> file(s) changed

── 3. DATA CLASSIFICATION ASSESSMENT ──────────────────────────────────────────

  INTERNAL  : <list files whose content is INTERNAL classification>
  CONFIDENTIAL: <list files touching credentials, PII, audit data, backup config>

  Ambiguous (defaulting to CONFIDENTIAL until reviewed):
    <list any file whose classification is unclear>

── 4. COMPLIANCE RISK FLAGS ───────────────────────────────────────────────────

  RGPD:
    □ No personal data introduced or modified           ← check or flag
    □ No new cross-border data flow                     ← check or flag
    □ Retention policies unaffected                     ← check or flag

  FedRAMP:
    □ No access control changes                         ← check or flag
    □ All inter-service TLS requirements preserved      ← check or flag
    □ Audit trail intact — no log suppression           ← check or flag
    □ Change follows formal CM-3 process                ← check or flag

  OPEN RISKS (if any):
    ⚠ <description of open risk, e.g. "new Ansible variable may expose hostname in logs">
      Recommendation: <mitigation>

── 5. EXCLUDED TECHNOLOGY CHECK ───────────────────────────────────────────────

  Verifying no excluded technology was introduced:
    □ Terraform  — not present in changeset
    □ Kubernetes — not present in changeset
    □ AWS        — not present in changeset
    □ GCP        — not present in changeset

  ⚠ VIOLATION (if any): <describe finding and location>

── 6. CARTRIDGE AUDIT ─────────────────────────────────────────────────────────

  Files missing cartridge block (### S-GLCR ###):
    <list, or "none">

  Files with stub cartridge (not yet populated by CI):
    <list — these will be populated on first CI run post-push>

── 7. LINTING GATE STATUS ─────────────────────────────────────────────────────

  shellcheck  : PASS | FAIL | NOT RUN
  Python CI   : PASS | FAIL | NOT RUN
  YAML lint   : PASS | FAIL | NOT RUN

  If any gate is FAIL or NOT RUN: push is BLOCKED until resolved or operator
  explicitly accepts the risk with a documented justification.

── 8. PROPOSED GIT COMMAND ────────────────────────────────────────────────────

  git add -A
  git commit -m "<commit message — 60 chars max>"
  git tag -a <project>-v<major>.<minor> -m "<tag message>"
  git push origin <branch>
  git push --tags

── 9. CONFIRMATION REQUIRED ───────────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────────────┐
  │  Review the checkpoint above.                                            │
  │                                                                          │
  │  Type  CONFIRM  to proceed with the push.                               │
  │  Type  ABORT    to cancel.                                              │
  │  Type  EDIT     to return to editing before re-running the checkpoint.  │
  └──────────────────────────────────────────────────────────────────────────┘
```

---

## Behavior on Response

| Operator input | Claude Code action |
|---|---|
| `CONFIRM` | Execute the proposed git commands exactly as shown in §8. Log the checkpoint to `/tmp/checkpoint-<epoch>.log` (INTERNAL). |
| `ABORT` | Cancel all git operations. Do not modify any file. Inform operator that no push was made. |
| `EDIT` | Return to the last editing state. Re-run the full checkpoint when the operator re-triggers a push. |
| Any other input | Treat as `ABORT`. Inform operator and ask for explicit `CONFIRM` or `ABORT`. |

---

## Audit Record

After a `CONFIRM`, Claude Code appends a checkpoint summary to the repository audit trail:

```
File: .claude/audit/checkpoint-<epoch>.txt
Classification: INTERNAL
```

Format:

```
CHECKPOINT AUDIT RECORD
=======================
Timestamp   : <ISO 8601 UTC>
Operator    : <git config user.name>
Branch      : <branch>
Commit      : <hash (populated post-push)>
Tag         : <tag>
Files changed: <N>
Demands     : <one-line summaries from §1>
Risks open  : <count> — see checkpoint-<epoch>.log for detail
Confirmed by: operator (explicit CONFIRM)
```

This file is committed as part of the push and provides an immutable record for FedRAMP CM-3
and AU-2 (Audit Events) compliance.

---

## Compliance Note

**RGPD**: The checkpoint provides the accountability record (Art. 5(2) GDPR) that processing
activities are managed and controlled. Any CONFIDENTIAL classification finding must be reviewed
before push — not after.

**FedRAMP**: Maps to control families:
- `CM-3` — Configuration Change Control (mandatory approval gate)
- `AU-2` — Audit Events (push actions are auditable events)
- `AU-9` — Protection of Audit Information (checkpoint log is immutable)
- `CM-9` — Configuration Management Plan (consistent, documented change process)