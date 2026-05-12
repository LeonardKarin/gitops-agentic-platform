---
name: hardcoded-path-risk
description: >
  Detects hardcoded filesystem paths that may break portability or create hidden
  environment dependencies.
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
---

<!--
 * @file        hardcoded-path-risk.md
 * @brief       Detects hardcoded filesystem paths
 * @details     Identifies absolute paths embedded in scripts that reduce
 *              portability or create environment lock-in.
-->

---

## Agent Identity

name: hardcoded-path-risk
model: claude-sonnet-4-6
permission_mode: auto

---

## Detection Patterns

/opt/
/tmp/
/home/
/var/
/etc/
/srv/
/usr/local/
/root/

---

## Execution

Detect:

absolute paths inside scripts
absolute paths inside ansible tasks
hardcoded temporary directories
hardcoded log directories

---

## Output

PATH RISK REPORT

file
line
path
risk level

---

## Recommendation

Prefer:

SCRIPT_DIR
environment variables
XDG paths
relative paths