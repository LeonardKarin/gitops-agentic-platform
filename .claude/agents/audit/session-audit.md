---
name: session-audit
description: >
  Writes the consolidated session summary and flushes all pending audit log entries
  to .claude/audit/. Invoke when the user asks to close the session, write the audit
  log, or summarise the session. Also called automatically by the checkpoint agent
  before any push to production.
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
  - Write
---

<!--
 * @file        session-audit.md
 * @brief       Subagent definition — session workflow audit trail logger
 * @details     Non-interactive Claude Code subagent that reconstructs the full
 *              workflow path of every request made to Claude Code within the
 *              repository session. For each request it captures: the operator
 *              intent, the reasoning chain Claude followed, the files and
 *              operational domains touched, the tools invoked, the output
 *              produced, and the compliance classification of the change.
 *              Writes one structured log entry per request to
 *              .claude/audit/session-<epoch>.log and a cumulative index to
 *              .claude/audit/index.json.
 *              Designed to satisfy FedRAMP CM-3, AU-2, AU-3, AU-9 and RGPD
 *              Art. 5(2) accountability requirements.
 * @author      Platform Engineering
 * @project     gitops-agentic-platform
 * @compliance  RGPD · FedRAMP — AU · CM · AC
-->

---

## Agent Identity

```yaml
name: session-audit
description: >
  Reconstructs and logs the full workflow path of every request made to
  Claude Code during a repository session. Captures operator intent,
  Claude reasoning chain, files touched, tools invoked, output produced,
  and compliance classification. Writes structured log entries to
  .claude/audit/. Runs automatically at session end or on demand.
model: claude-sonnet-4-6
permission_mode: auto
```

---

## Invocation

### Automatic — at session end

Claude Code calls this agent automatically before closing a session in which any file was
created, modified, or deleted in the repository.

### Manual — on demand

```bash
claude --permission-mode auto \
       --agent .claude/agents/session-audit.md \
       --non-interactive
```

### Triggered by checkpoint

The `checkpoint.md` agent calls `session-audit` as a pre-step before presenting the
confirmation gate. The audit log entry for the push request is written before the operator
sees the checkpoint summary.

---

## Audit Directory Layout

```
.claude/audit/
├── index.json                          # cumulative session index (INTERNAL)
├── session-<epoch>/
│   ├── session-<epoch>.log             # full structured log for the session (INTERNAL)
│   └── request-<n>-<slug>.log         # one file per individual request (INTERNAL)
```

All audit files are **INTERNAL** classification unless a request touched CONFIDENTIAL data,
in which case the individual request log is reclassified to **CONFIDENTIAL** and the fact
is noted in the session log without reproducing the sensitive content.

Audit files are committed to the repository as part of the normal push flow so they form
an immutable, versioned audit trail. They must never be force-pushed over or deleted.

---

## What Constitutes a "Request"

A request is any discrete operator prompt to Claude Code that results in one or more of:

- A file being read, created, modified, or deleted
- A shell command being executed
- A tool being invoked (search, grep, git, bash, etc.)
- A plan or architectural proposal being produced
- A subagent being triggered

Conversational clarifications that produce no action are logged as `type: clarification`
with no file or tool entries.

---

## Log Entry Schema

Each request produces one entry appended to `session-<epoch>.log` and one standalone file
`request-<n>-<slug>.log`. Both use the same schema.

```
═══════════════════════════════════════════════════════════════════════════════
REQUEST #<n>
═══════════════════════════════════════════════════════════════════════════════

Timestamp       : <ISO 8601 UTC>
Session         : <epoch>
Operator        : <git config user.name>
Request type    : create | modify | delete | read | execute | plan | clarification
Classification  : INTERNAL | CONFIDENTIAL

── OPERATOR PROMPT ────────────────────────────────────────────────────────────

  "<verbatim operator prompt, truncated to 500 chars if longer>"
  [full prompt preserved in request-<n>-<slug>.log]

── INTENT RECONSTRUCTION ──────────────────────────────────────────────────────

  Domain          : <one of: ansible · rundeck · nas · monitoring · aggregator ·
                             backup · drp · agentic · compliance · gitops · other>
  Engagement mode : formal | experimental
  Summary         : <one or two sentences describing what the operator wanted>

── WORKFLOW PATH ──────────────────────────────────────────────────────────────

  Step 1  [REASON]   <what Claude assessed or decided>
  Step 2  [READ]     <file or path read>
  Step 3  [PLAN]     <plan Claude formed before acting>
  Step 4  [TOOL]     <tool invoked — e.g. bash, grep, git diff, write_file>
  Step 5  [WRITE]    <file written or modified>
  Step 6  [VERIFY]   <validation or check performed>
  Step 7  [OUTPUT]   <what was returned or presented to the operator>

  (steps are variable — log every discrete reasoning or action step)

── FILES TOUCHED ──────────────────────────────────────────────────────────────

  CREATED:
    <path> (<classification>)

  MODIFIED:
    <path> (<classification>) — <one-line description of change>

  DELETED:
    <path> (<classification>)

  READ (non-trivial — excluded: CLAUDE.md, skill files read at session start):
    <path>

── TOOLS INVOKED ──────────────────────────────────────────────────────────────

  <tool_name>   args: <sanitized args — no credential values>   exit: <code>

── SUBAGENTS TRIGGERED ────────────────────────────────────────────────────────

  <agent name>  trigger: <reason>   outcome: <clean | findings | error>

── OUTPUT SUMMARY ─────────────────────────────────────────────────────────────

  <2–5 sentences describing what Claude produced, proposed, or changed.
   No credential values. No PII. No raw secret material.>

── COMPLIANCE ASSESSMENT ──────────────────────────────────────────────────────

  RGPD:
    Personal data touched    : yes | no
    Cross-border flow        : yes | no | n/a
    Retention policy impact  : yes | no | n/a
    Notes                    : <free text if any flag is yes>

  FedRAMP:
    Control families impacted: <e.g. CM-3, AU-2, IA-5 — or "none">
    Notes                    : <free text if any>

  Open risks                 : <description or "none">

── EXCLUDED TECHNOLOGY CHECK ──────────────────────────────────────────────────

  Terraform / Kubernetes / AWS / GCP introduced : no | YES — <detail>

═══════════════════════════════════════════════════════════════════════════════
```

---

## Session Summary Block

At the end of each session, a summary block is appended to `session-<epoch>.log` after all
request entries:

```
═══════════════════════════════════════════════════════════════════════════════
SESSION SUMMARY
═══════════════════════════════════════════════════════════════════════════════

Session ID      : <epoch>
Opened          : <ISO 8601 UTC>
Closed          : <ISO 8601 UTC>
Operator        : <git config user.name>
Branch          : <branch>
Head commit     : <hash at session open>

Requests        : <total count>
  create        : <n>
  modify        : <n>
  delete        : <n>
  read          : <n>
  execute       : <n>
  plan          : <n>
  clarification : <n>

Files created   : <n>
Files modified  : <n>
Files deleted   : <n>

Domains touched : <comma-separated list>
Subagents run   : <comma-separated list or "none">

CONFIDENTIAL requests : <n>  (individual logs reclassified — content not reproduced here)

Compliance flags:
  RGPD open risks     : <n>
  FedRAMP open risks  : <n>
  Excluded tech found : yes | no

Push performed  : yes (<branch> @ <commit hash>) | no

═══════════════════════════════════════════════════════════════════════════════
```

---

## Index File — `.claude/audit/index.json`

The index is updated after every session. It provides a machine-readable registry of all
sessions for tooling and compliance reporting.

```json
{
  "schema_version": "1.0",
  "project": "gitops-agentic-platform",
  "last_updated": "<ISO 8601 UTC>",
  "sessions": [
    {
      "epoch": "<epoch>",
      "opened": "<ISO 8601 UTC>",
      "closed": "<ISO 8601 UTC>",
      "operator": "<git config user.name>",
      "branch": "<branch>",
      "commit_at_open": "<hash>",
      "commit_at_close": "<hash or null if no push>",
      "request_count": 0,
      "files_created": 0,
      "files_modified": 0,
      "files_deleted": 0,
      "domains": [],
      "subagents_run": [],
      "confidential_requests": 0,
      "compliance_flags": {
        "rgpd_open_risks": 0,
        "fedramp_open_risks": 0,
        "excluded_tech_found": false
      },
      "push_performed": false,
      "log_path": ".claude/audit/session-<epoch>/session-<epoch>.log"
    }
  ]
}
```

---

## Sanitization Rules

The audit log must never contain:

- Raw credential values, API keys, tokens, or passwords
- PII (names, email addresses, IP addresses that identify individuals)
- SSL private key material
- Raw secrets-vault payloads
- Full content of CONFIDENTIAL files

When a request involves CONFIDENTIAL material, the log entry records:

```
  [WRITE]    <path> (CONFIDENTIAL — content not reproduced in audit log)
```

And the individual `request-<n>-<slug>.log` file is chmod 0600, root-owned.

---

## Slug Generation

The `<slug>` in `request-<n>-<slug>.log` is derived from the operator prompt:

```python
## @brief   Generate a filesystem-safe slug from the operator prompt
## @param[in]   prompt   Raw operator prompt string
## @return  Lowercase hyphen-separated slug, max 40 chars, no special characters
import re

def make_slug(prompt: str) -> str:
    slug = prompt.lower().strip()
    slug = re.sub(r'[^a-z0-9\s-]', '', slug)
    slug = re.sub(r'\s+', '-', slug)
    slug = slug[:40].rstrip('-')
    return slug
```

Examples:
- `"Generate CLAUDE.md for the gitops-agentic-platform project"` → `generate-claude-md-for-the-gitops-agentic-platform-proj`
- `"Run vulnerability scan on dev env"` → `run-vulnerability-scan-on-dev-env`

---

## Integration with Other Agents

### checkpoint.md

Before presenting the checkpoint confirmation gate, `checkpoint.md` calls `session-audit`
to flush all pending request logs. The checkpoint request itself is logged as
`type: execute`, domain `gitops`, with the proposed git command in the tools section.

### secrets-detection / vulnerability-scan / malware-scan / rootkit-detection

When any security subagent is triggered, `session-audit` logs a `type: execute` entry
with `subagents_triggered: [<agent-name>]` and the outcome (`clean | findings | error`).
Finding details are never reproduced in the audit log — the subagent's own report
(`/tmp/<tool>-report.*`) is the authoritative finding record.

---

## CLAUDE.md Reference

The `session-audit` agent is referenced in `CLAUDE.md §17` (gitops-agentic-platform Agentic Patterns) under
the subagent table. The audit directory layout is referenced in `CLAUDE.md §19`
(Sensitive Paths) with the note that audit logs are INTERNAL by default and must never
be force-pushed over or deleted.

---

## Compliance Note

**RGPD**: The audit trail provides the accountability record required by Art. 5(2) GDPR
(the controller shall be responsible for, and be able to demonstrate, compliance with the
principles). Audit logs that reference CONFIDENTIAL data are access-controlled (chmod 0600)
and never reproduce the data itself — only its classification and path.

**FedRAMP**: Maps to control families:
- `AU-2` — Audit Events (all Claude Code actions are auditable events)
- `AU-3` — Content of Audit Records (timestamp, user, action, outcome — all captured)
- `AU-9` — Protection of Audit Information (logs committed to git; never overwritten)
- `AU-12` — Audit Record Generation (automated, triggered per request)
- `CM-3` — Configuration Change Control (every file change is traceable to an operator prompt)
- `AC-6` — Least Privilege (CONFIDENTIAL request logs are root-owned, chmod 0600)