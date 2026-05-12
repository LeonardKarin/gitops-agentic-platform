# run-agent.sh (updated)

#!/usr/bin/env bash
## @file        run-agent.sh
## @brief       Convenience wrapper to invoke any shared Claude Code agent
## @details     Resolves the agent file from .claude/agents/, builds the correct
##              claude -p invocation, and executes it. Removes the need for
##              operators to remember CLI flag syntax. Symlinked into each
##              consuming repo root by bootstrap.sh.
##
##              Usage:
##                bash run-agent.sh <agent-name>
##
##              Available agents:
##                secrets-detection
##                vulnerability-scan
##                malware-scan
##                rootkit-detection
##                session-audit
##                checkpoint
##                dependency-vulnerability-audit
##                supply-chain-risk
##                hardcoded-path-risk
##                privilege-escalation-risk
##                unsafe-tempfile-usage
##                refactor-safety-check
##                dead-code-detection
##                complexity-hotspot-detection
##                ansible-idempotency-check
##                bash-strict-mode-check
##                logging-consistency
##                config-drift-detection
##                repo-structure-check
##                layering-violation-check
##                interface-contract-check
##                change-impact-assessment
##                backward-compatibility-check
##                runtime-risk-estimation
##                docstring-quality
##                cli-ux-consistency
##
##              Examples:
##                bash run-agent.sh secrets-detection
##                bash run-agent.sh repo-structure-check
##
## @author      Platform Engineering
## @note        Classification: INTERNAL
## @warning     Must be run from the consuming repo root — not from gitops-agentic-platform itself

### S-GLCR ###
### E-GLCR ###

set -euo pipefail
IFS=$'\n\t'

# ── constants ──────────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly AGENTS_DIR=".claude/agents"

readonly -a KNOWN_AGENTS=(
	"secrets-detection"
	"vulnerability-scan"
	"malware-scan"
	"rootkit-detection"
	"session-audit"
	"checkpoint"
	"dependency-vulnerability-audit"
	"supply-chain-risk"
	"hardcoded-path-risk"
	"privilege-escalation-risk"
	"unsafe-tempfile-usage"
	"refactor-safety-check"
	"dead-code-detection"
	"complexity-hotspot-detection"
	"ansible-idempotency-check"
	"bash-strict-mode-check"
	"logging-consistency"
	"config-drift-detection"
	"repo-structure-check"
	"layering-violation-check"
	"interface-contract-check"
	"change-impact-assessment"
	"backward-compatibility-check"
	"runtime-risk-estimation"
	"docstring-quality"
	"cli-ux-consistency"
)

# ── colours ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
	_green='\033[0;32m'; _yellow='\033[1;33m'
	_red='\033[0;31m';   _cyan='\033[0;36m'
	_reset='\033[0m'
else
	_green=''; _yellow=''; _red=''; _cyan=''; _reset=''
fi

# ── logging ───────────────────────────────────────────────────────────────────

## @brief   Emit a timestamped INFO line to stdout
_log_info()  { printf "${_green}[%s] INFO  %s${_reset}\n" "$(date -u +%FT%TZ)" "$*"; }

## @brief   Emit a timestamped WARN line to stdout
_log_warn()  { printf "${_yellow}[%s] WARN  %s${_reset}\n" "$(date -u +%FT%TZ)" "$*"; }

## @brief   Emit a timestamped ERROR line to stderr and exit 1
_log_error() { printf "${_red}[%s] ERROR %s${_reset}\n"  "$(date -u +%FT%TZ)" "$*" >&2; exit 1; }

# ── usage ─────────────────────────────────────────────────────────────────────

## @brief   Print usage and list of known agents, then exit
_usage() {
	printf 'Usage: %s <agent-name>\n\n' "${SCRIPT_NAME}"
	printf 'Available agents:\n'
	for _a in "${KNOWN_AGENTS[@]}"; do
		printf '  %s\n' "${_a}"
	done
	printf '\nExamples:\n'
	printf '  bash %s secrets-detection\n' "${SCRIPT_NAME}"
	printf '  bash %s repo-structure-check\n' "${SCRIPT_NAME}"
	exit 0
}

# ── preflight ─────────────────────────────────────────────────────────────────

## @brief   Verify claude CLI is available on PATH
_check_claude() {
	if ! command -v claude &>/dev/null; then
		_log_error "claude CLI not found on PATH. Install Claude Code first:
  https://docs.anthropic.com/en/docs/claude-code"
	fi
}

## @brief   Verify the agent file exists (symlink or real file)
## @param[in]  $1  path to agent .md file
_check_agent_file() {
	local _f="${1}"
	if [[ ! -f "${_f}" ]]; then
		_log_error "Agent file not found: ${_f}
  Did you run bootstrap.sh in this repo?
  Does /opt/git/gitops-agentic-platform exist on this machine?"
	fi
}

## @brief   Verify script is run from a git repository root
_check_git_root() {
	if ! git rev-parse --show-toplevel &>/dev/null; then
		_log_error "Not inside a git repository. Run from the consuming repo root."
	fi
	local _root
	_root="$(git rev-parse --show-toplevel)"
	if [[ "$(pwd)" != "${_root}" ]]; then
		_log_error "Must be run from the repository root: ${_root}"
	fi
}

## @brief   Verify the requested agent is in the known list
## @param[in]  $1  agent name
_check_known_agent() {
	local _requested="${1}"
	local _known=false
	local _a
	for _a in "${KNOWN_AGENTS[@]}"; do
		if [[ "${_a}" == "${_requested}" ]]; then
			_known=true
			break
		fi
	done

	if [[ "${_known}" != true ]]; then
		_log_error "Unknown agent: ${_requested}
Run 'bash ${SCRIPT_NAME} --help' to list supported agents."
	fi
}

# ── main ──────────────────────────────────────────────────────────────────────

## @brief   Entry point
## @param[in]  $1  agent name (without .md extension)
## @param[in]  $2  optional: safe to keep interactive permission prompts
main() {
	if [[ $# -eq 0 ]] || [[ "${1}" == "--help" ]] || [[ "${1}" == "-h" ]]; then
		_usage
	fi

	local _agent="${1}"
	local _mode="${2:-unsafe}"
	local _agent_file="${AGENTS_DIR}/${_agent}.md"

	_check_claude
	_check_git_root
	_check_known_agent "${_agent}"
	_check_agent_file "${_agent_file}"

	_log_info "Invoking agent : ${_cyan}${_agent}${_reset}"
	_log_info "Agent file     : ${_agent_file}"
	_log_info "Permission mode: ${_mode}"
	_log_info "Claude CLI     : $(command -v claude)"
	printf '\n'

	if [[ "${_mode}" == "safe" ]]; then
		claude -p "Execute the following agent runbook exactly as specified.
Follow every step in order. Do not skip any section.

$(cat "${_agent_file}")" \
			--allowedTools "Bash,Read,Write" \
			--permission-mode auto
	else
		claude -p "Execute the following agent runbook exactly as specified.
Follow every step in order. Do not skip any section.

$(cat "${_agent_file}")" \
			--dangerously-skip-permissions
	fi

	local _exit=$?
	printf '\n'
	if (( _exit == 0 )); then
		_log_info "Agent ${_agent} completed successfully."
	else
		_log_warn "Agent ${_agent} exited with code ${_exit}."
	fi
	return ${_exit}
}

main "$@"