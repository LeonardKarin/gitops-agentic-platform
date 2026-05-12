---
name: unsafe-tempfile-usage
description: >
  Detects insecure temporary file handling patterns.
model: claude-haiku-4-5-20251001
tools:
  - Bash
  - Read
---

<!--
 * @file unsafe-tempfile-usage.md
-->

---

## Agent Identity

name: unsafe-tempfile-usage
model: claude-sonnet-4-6
permission_mode: auto

---

## Detection

/tmp/file
/tmp/output
predictable filenames
missing mktemp
missing cleanup

---

## Recommendation

use mktemp
remove temporary files
avoid predictable filenames

---

## Compliance

OWASP secure temp file handling