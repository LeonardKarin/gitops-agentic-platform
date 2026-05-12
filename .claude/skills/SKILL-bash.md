---
name: bash-standards
description: Use this skill when generating, reviewing, or refactoring Bash or shell scripts. Enforces GNU Bash strict mode, safe quoting, _snake_case function naming, shellcheck compliance, shell-lib linkage patterns, and operational safety rules.
---

# Bash Standards Skill

Use this skill when working on shell scripts in this repository.

This skill applies to:

Rundeck job scripts
helper scripts
Ansible helper scripts
replication scripts
launchers
general Bash utilities

It complements the repository global standards and adds Bash-specific discipline.

-------------------------------------------------------------------------------

## Objectives

Produce Bash scripts that are:

safe
readable
strict-mode compatible
operationally predictable
shellcheck-clean
aligned with repository conventions

-------------------------------------------------------------------------------

## Required Bash baseline

Use GNU Bash.

Executable scripts must begin with:

#!/usr/bin/env bash

Immediately enable strict mode:

set -euo pipefail
IFS=$'\n\t'

Do not disable strict mode globally.

-------------------------------------------------------------------------------

## Function conventions

Use:

_snake_case for internal helper functions
main for the primary entrypoint

Every meaningful function should be documented with a structured Bash comment
block.

Use local for function-scoped variables.

Avoid implicit global variables created from inside functions.

-------------------------------------------------------------------------------

## Variable handling

Always quote expansions.

Use ${var} style consistently.

Use safe expansion patterns:

${VAR:-default}
${VAR:?message}

Use readonly for constants.

Use clear names and avoid cryptic abbreviations.

-------------------------------------------------------------------------------

## Conditional and loop style

Use [[ ]] for conditionals.

Use arrays for collections.

Use associative arrays only when key/value behavior is required.

Keep loops readable and safe under strict mode.

-------------------------------------------------------------------------------

## Logging and errors

Use explicit logging helpers.

Prefer patterns like:

_log_info
_log_warn
_log_error

Never log secrets or confidential payloads.

Use traps when cleanup or audit behavior matters.

Handle expected failures explicitly rather than weakening strict mode.

-------------------------------------------------------------------------------

## Command substitution and pipelines

Always use $() rather than backticks.

Be careful with pipeline and substitution failure behavior under:

set -euo pipefail

Capture and handle failures explicitly when needed.

-------------------------------------------------------------------------------

## Shared library usage

When using shell-lib or shared repository helpers:

resolve paths relative to SCRIPT_DIR
use source safely
keep shellcheck annotations specific and justified

Example:

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../shell-lib/linkage.sh
source "${SCRIPT_DIR}/../../shell-lib/linkage.sh"

-------------------------------------------------------------------------------

## ShellCheck expectations

Scripts must pass shellcheck with severity=error.

Suppressions are allowed only when:

they target a specific rule
they are justified
they are local to the issue

Do not use broad suppressions.

-------------------------------------------------------------------------------

## Heredoc usage

Use heredocs for multiline rendering or generated configuration.

Prefer <<-EOF when tab-stripping helps preserve indentation style.

Avoid messy heredocs with unclear variable expansion behavior.

-------------------------------------------------------------------------------

## Operational safety expectations

Generated scripts must not:

expose secrets
assume unsafe execution environments
modify managed artifacts outside approved flows
depend on hidden side effects
introduce fragile path assumptions

Prefer explicit, defensive logic.

-------------------------------------------------------------------------------

## Review checklist

When reviewing a shell script, verify:

correct shebang
strict mode present
safe quoting
local variable usage inside functions
valid function naming
no deprecated backticks
safe error handling
no secret leakage
shellcheck compatibility
clear operational flow

-------------------------------------------------------------------------------

## Expected output quality

Generated Bash code should be:

boringly reliable
easy to audit
safe in production
minimal in diff size when editing existing files

Prefer maintainable scripts over clever shell tricks.

-------------------------------------------------------------------------------

## Relationship with global standards

Global standards always apply first.

Bash-specific rules extend the repository-wide requirements for formatting,
security, naming, and documentation.