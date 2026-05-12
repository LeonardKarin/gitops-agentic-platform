<!--
 * @file        INVOCATION.md
 * @brief       Correct Claude Code CLI invocation patterns for all shared agents
 * @details     Documents the verified CLI flags for claude (Claude Code) as of
 *              the current release. Replaces all prior references to the
 *              non-existent --non-interactive flag throughout agent definitions.
 *              Reference: claude --help
 * @author      Platform Engineering
 * @project     gitops-agentic-platform
 * @note        Classification: INTERNAL
-->

### S-GLCR ###
### E-GLCR ###

---

## Verified Claude Code CLI flags

```
claude [options] [prompt]

Key flags:
  -p, --print           Non-interactive mode — run prompt and exit (no REPL)
  --allowedTools        Comma-separated list of permitted tools
  --permission-mode     auto | default | bypassPermissions
  --model               Model to use (default: claude-sonnet-4-6)
  --system-prompt       Override system prompt
  --no-streaming        Disable streaming output
  --output-format       text | json | stream-json
```

`--non-interactive` does **not exist** — use `-p` instead.

---

## Agent invocation patterns

### Pattern 1 — pipe agent file as prompt (recommended)

Passes the full agent runbook to Claude as the task. Claude reads, plans,
and executes it non-interactively then exits.

```bash
claude -p "$(cat .claude/agents/<agent>.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### Pattern 2 — explicit instruction + agent file

More explicit — useful when the agent file is long and you want Claude to
clearly understand it is a runbook to execute, not documentation to summarise.

```bash
claude -p "Execute the following agent runbook exactly as specified.
Follow every step in order. Do not skip sections.

$(cat .claude/agents/<agent>.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### Pattern 3 — stdin pipe

Clean for scripting and CI pipelines.

```bash
cat .claude/agents/<agent>.md \
  | claude -p - \
           --allowedTools "Bash,Read,Write" \
           --permission-mode auto
```

---

## Per-agent invocations (copy-paste ready)

### secrets-detection

```bash
claude -p "$(cat .claude/agents/secrets-detection.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### vulnerability-scan

```bash
claude -p "$(cat .claude/agents/vulnerability-scan.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### malware-scan

```bash
claude -p "$(cat .claude/agents/malware-scan.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### rootkit-detection

```bash
claude -p "$(cat .claude/agents/rootkit-detection.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### session-audit

```bash
claude -p "$(cat .claude/agents/session-audit.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

### checkpoint (pre-push gate)

```bash
claude -p "$(cat .claude/agents/checkpoint.md)" \
       --allowedTools "Bash,Read,Write" \
       --permission-mode auto
```

---

## Wrapper script — run-agent.sh

A convenience wrapper so operators never have to remember the flag syntax:

```bash
#!/usr/bin/env bash
## @file        run-agent.sh
## @brief       Convenience wrapper to invoke a shared Claude Code agent
## @usage       bash run-agent.sh <agent-name>
##              bash run-agent.sh secrets-detection
## @note        Classification: INTERNAL

### S-GLCR ###
### E-GLCR ###

set -euo pipefail

readonly AGENTS_DIR=".claude/agents"
readonly _agent="${1:?agent name required — e.g. secrets-detection}"
readonly _agent_file="${AGENTS_DIR}/${_agent}.md"

[[ -f "${_agent_file}" ]] \
  || { echo "ERROR: agent file not found: ${_agent_file}"; exit 1; }

echo "Running agent: ${_agent}"
echo "File: ${_agent_file}"
echo "---"

claude -p "Execute the following agent runbook exactly as specified.
Follow every step in order. Do not skip sections.

$(cat "${_agent_file}")" \
  --allowedTools "Bash,Read,Write" \
  --permission-mode auto
```

Usage:

```bash
bash run-agent.sh secrets-detection
bash run-agent.sh vulnerability-scan
bash run-agent.sh malware-scan
bash run-agent.sh rootkit-detection
bash run-agent.sh session-audit
bash run-agent.sh checkpoint
```

---

## CI pipeline usage (.github/workflows/ci.yml)

```yaml
security-scan:
  stage: lint
  script:
    - bash run-agent.sh secrets-detection
    - bash run-agent.sh vulnerability-scan
  rules:
    - if: '$GITHUB_REF_NAME == "refs/heads/main"'
```

---

## README.md correction

All agent invocation examples in `README.md` must use `-p "$(cat ...)"` form.
The `--non-interactive` flag referenced in prior versions of that file does not exist
and must be removed. See per-agent examples above.