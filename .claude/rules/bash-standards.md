---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Bash and Shell standards

These rules apply to all shell scripts in this repository, including Rundeck job
scripts, helper scripts, launchers, sync scripts, and operational utilities.

These rules extend global-standards.md and must not contradict it.

-------------------------------------------------------------------------------

## Shell target

Use GNU Bash for all new shell scripts unless the file is explicitly required to
be POSIX sh-compatible.

Executable Bash scripts must start with:

#!/usr/bin/env bash

Do not use /bin/bash directly unless there is a hard platform requirement.

-------------------------------------------------------------------------------

## File structure

Use this order when applicable:

1. shebang
2. structured documentation block
3. cartridge placeholder
4. strict mode
5. constants
6. library sourcing
7. private functions
8. main function
9. main call

Example cartridge placeholder:

### S-GLCR ###
### E-GLCR ###

-------------------------------------------------------------------------------

## Strict mode

Every Bash script must enable strict mode immediately after the header and
cartridge block.

Required block:

set -euo pipefail
IFS=$'\n\t'

Do not disable strict mode globally.

If a command is expected to return a non-zero code, handle it explicitly.

Example:

_found=$(grep "pattern" "${_file}") || true

-------------------------------------------------------------------------------

## Comments

Use Bash-native comment syntax only.

Use:

## for structured documentation blocks
# for inline comments
### for cartridge delimiters or visible section separators

Example:

## @brief   Validate NAS hostname
## @param[in]  $1  Hostname
## @return  0 if valid, 1 otherwise

Never use:

// or /* */

These are invalid or unsafe in shell scripts.

-------------------------------------------------------------------------------

## Indentation

Use tabs in shell scripts, following repository conventions.

Do not mix tabs and spaces for indentation in the same file.

Align wrapped commands consistently.

-------------------------------------------------------------------------------

## Variables

Variable naming rules:

local function variables:
_snake_case

script-level mutable variables:
_snake_case

readonly constants:
SCREAMING_SNAKE_CASE

exported environment variables:
SCREAMING_SNAKE_CASE

Examples:

readonly MAX_JOBS=4
_target_host=""

Use local for function-scoped variables.

Do not create implicit globals from inside functions.

-------------------------------------------------------------------------------

## Safe expansion

Always quote variable expansions.

Use ${var} form consistently.

Correct:

rsync -av "${_src}/" "${_dst}/"

Incorrect:

rsync -av $_src/ $_dst/

Use safe parameter expansion:

${VAR:-default}
${VAR:?message}

Examples:

_timeout="${BACKUP_TIMEOUT:-3600}"
local _host="${1:?hostname is required}"

-------------------------------------------------------------------------------

## Functions

Function naming rules:

Private/internal helpers:
_snake_case

Public entry points:
main or explicitly documented exported API functions

Every function should have a structured documentation block immediately above it
when the function is non-trivial or part of operational logic.

Use local for all internal function variables.

Return codes:

0 = success
1 = generic error
Other codes must be documented if used

-------------------------------------------------------------------------------

## Main entrypoint

Prefer a main() function.

Call it explicitly at the end:

main "$@"

Do not place operational logic loose at file scope unless the script is
intentionally trivial.

-------------------------------------------------------------------------------

## Command substitution

Always use $().

Correct:

_output=$(some_command "${_arg}")

Incorrect:

_output=`some_command ${_arg}`

Backticks are forbidden.

-------------------------------------------------------------------------------

## Conditionals

Use [[ ]] for Bash conditionals.

Correct:

if [[ "${_mode}" == "azure" ]]; then
	...
fi

Use [[ ... =~ ... ]] for regex checks when needed.

Do not rely on [ ] when Bash features are required.

-------------------------------------------------------------------------------

## Loops and arrays

Prefer arrays for collections.

Example:

declare -a _hosts=("nas-node-01" "nas-node-02")

for _host in "${_hosts[@]}"; do
	_sync_to_remote "${_host}"
done

Use associative arrays only when key/value mapping is actually needed.

Example:

declare -A DC_FLOW

-------------------------------------------------------------------------------

## Error handling

Use explicit error handling and traps where operationally relevant.

Example pattern:

_on_exit() {
	local _rc=$?
	(( _rc != 0 )) && _log_error "script exited with code ${_rc}"
}

trap '_on_exit' EXIT
trap '_on_exit; exit 130' INT TERM

Do not swallow errors silently.

Do not use fragile patterns that bypass strict mode unintentionally.

-------------------------------------------------------------------------------

## Logging

Logging must be explicit, timestamped, and safe.

Never log:

passwords
tokens
private keys
vault-derived secrets
raw confidential payloads
PII

Prefer helper functions such as:

_log_info
_log_warn
_log_error

Log operational intent and scope, not secret values.

-------------------------------------------------------------------------------

## Subprocess and pipeline safety

With set -euo pipefail enabled, always treat pipelines and command substitutions
carefully.

If a command may fail as part of normal control flow, handle that failure
explicitly.

Example:

_output=$(risky_command) || {
	_log_error "risky_command failed"
	exit 1
}

-------------------------------------------------------------------------------

## Shell library linkage

When using shared shell libraries, source them relative to SCRIPT_DIR.

Do not use hardcoded absolute paths for repository libraries.

Example pattern:

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../../shell-lib/linkage.sh
source "${SCRIPT_DIR}/../../shell-lib/linkage.sh"
_link access-lib dbaccess-lib

Use shellcheck source= directives when needed to avoid false positives.

-------------------------------------------------------------------------------

## Heredocs

Use heredocs for multiline output or config generation.

Prefer <<-EOF when tab-stripping is required.

Example:

_generate_config() {
	local _host="${1:?}"
	cat <<-EOF
		key=value
		host=${_host}
	EOF
}

Do not indent heredoc bodies with spaces when using <<-EOF.

-------------------------------------------------------------------------------

## Parallel execution

Parallel execution must be explicit, bounded, and readable.

If using xargs, keep worker count controlled and arguments safely quoted.

Do not introduce uncontrolled concurrency in production scripts.

-------------------------------------------------------------------------------

## ShellCheck compliance

All shell scripts must pass shellcheck with severity=error before merge.

Allowed suppressions must be:

specific
justified
local

Correct:

# shellcheck disable=SC1091  # sourced at runtime via SCRIPT_DIR
# shellcheck disable=SC2034  # exported for child process consumption

Do not use blanket disables without code and justification.

-------------------------------------------------------------------------------

## Operational safety

Production execution must respect repository operational rules.

Do not:

run uncontrolled scripts directly on remote client VMs
hardcode deployment paths when a repo-relative pattern exists
edit generated inventory artifacts manually
log confidential data
modify managed storage paths by hand outside the deployment process

Generated or managed files must be treated as owned by the automation flow.

-------------------------------------------------------------------------------

## General expectations

Shell scripts must be:

readable
defensive
portable within repository constraints
safe under strict mode
maintainable

Avoid:

unquoted expansions
implicit globals
deprecated syntax
hidden side effects
clever one-liners that reduce readability