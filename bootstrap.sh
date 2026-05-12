#!/usr/bin/env bash
## @file        bootstrap.sh
## @brief       First-time setup of the gitops-agentic-platform shared layer in a consuming repo
## @details     Copies (not symlinks) skill, rule and agent files from /opt/git/gitops-agentic-platform
##              into the consuming repository and into $HOME/.claude/ where required so
##              Claude Code v2.x file scanning picks them up correctly.
##              Symlinks are not followed by Claude Code's internal scanner — real files
##              are required.
##
##              Keeps project-level flat copies of SKILL-*.md for human reference and
##              auditability, while also deploying runtime skills under
##              $HOME/.claude/skills/<skill-name>/SKILL.md for Claude Code v2.x.
##
##              Installs the post-commit git hook. Creates .claude/audit/ with .gitkeep.
##              Patches .gitignore. Injects the shared-layer reference block into
##              CLAUDE.md. Idempotent — safe to re-run for updates.
##
##              Prerequisites:
##                /opt/git/gitops-agentic-platform/ must exist (run machine setup first):
##                  sudo git clone git@github.com/your-org:saas/gitops-agentic-platform.git \
##                    /opt/git/gitops-agentic-platform
##
##              Usage (from consuming repo root):
##                bash /opt/git/gitops-agentic-platform/bootstrap.sh
##
##              To update after gitops-agentic-platform changes:
##                cd /opt/git/gitops-agentic-platform && sudo git pull origin production
##                bash /opt/git/gitops-agentic-platform/bootstrap.sh
##
## @author      Platform Engineering
## @project     gitops-agentic-platform
## @note        Classification: INTERNAL
## @warning     Run from the consuming repo root — not from inside gitops-agentic-platform itself

### S-GLCR ###
### E-GLCR ###

set -euo pipefail
IFS=$'\n\t'

# ── constants ──────────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SHARED_ROOT="/opt/git/gitops-agentic-platform"
readonly CLAUDE_DIR=".claude"
readonly SKILLS_DIR="${CLAUDE_DIR}/skills"
readonly RULES_DIR="${CLAUDE_DIR}/rules"
readonly AGENTS_DIR="${CLAUDE_DIR}/agents"
readonly AUDIT_DIR="${CLAUDE_DIR}/audit"
readonly GITHOOKS_DIR=".githooks"
readonly CLAUDE_MD="CLAUDE.md"

readonly -a SKILL_FILES=(
	"SKILL-global.md"
	"SKILL-bash.md"
	"SKILL-python.md"
	"SKILL-ansible.md"
	"SKILL-perl.md"
)

readonly -a RULE_FILES=(
	"global-standards.md"
	"bash-standards.md"
	"python-standards.md"
	"ansible-standards.md"
	"perl-standards.md"
)

readonly -a AGENT_FILES=(
	"security/secrets-detection.md"
	"security/vulnerability-scan.md"
	"security/malware-scan.md"
	"security/rootkit-detection.md"
	"audit/session-audit.md"
	"workflow/checkpoint.md"
	"security/dependency-vulnerability-audit.md"
	"security/supply-chain-risk.md"
	"infra/hardcoded-path-risk.md"
	"security/privilege-escalation-risk.md"
	"security/unsafe-tempfile-usage.md"
	"quality/refactor-safety-check.md"
	"quality/dead-code-detection.md"
	"quality/complexity-hotspot-detection.md"
	"infra/ansible-idempotency-check.md"
	"infra/bash-strict-mode-check.md"
	"quality/logging-consistency.md"
	"infra/config-drift-detection.md"
	"infra/repo-structure-check.md"
	"quality/layering-violation-check.md"
	"quality/interface-contract-check.md"
	"audit/change-impact-assessment.md"
	"audit/backward-compatibility-check.md"
	"audit/runtime-risk-estimation.md"
	"quality/docstring-quality.md"
	"quality/cli-ux-consistency.md"
	"invocation.md"
)

readonly -a REPO_ROOT_FILES=(
	"run-agent.sh"
)

# ── colours ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
	_green='\033[0;32m'; _yellow='\033[1;33m'
	_red='\033[0;31m';   _reset='\033[0m'
else
	_green=''; _yellow=''; _red=''; _reset=''
fi

# ── logging ───────────────────────────────────────────────────────────────────

## @brief   Emit a timestamped INFO line to stdout
_log_info()  { printf "${_green}[%s] INFO  %s${_reset}\n" "$(date -u +%FT%TZ)" "$*"; }

## @brief   Emit a timestamped WARN line to stdout
_log_warn()  { printf "${_yellow}[%s] WARN  %s${_reset}\n" "$(date -u +%FT%TZ)" "$*"; }

## @brief   Emit a timestamped ERROR line to stderr and exit 1
_log_error() { printf "${_red}[%s] ERROR %s${_reset}\n" "$(date -u +%FT%TZ)" "$*" >&2; exit 1; }

# ── preflight checks ──────────────────────────────────────────────────────────

## @brief   Verify the shared clone exists at the expected path
_check_shared_root() {
	if [[ ! -d "${SHARED_ROOT}/.claude/skills" ]]; then
		_log_error "Shared layer not found at ${SHARED_ROOT}. Run machine setup first:
  sudo git clone git@github.com/your-org:saas/gitops-agentic-platform.git ${SHARED_ROOT}"
	fi
	_log_info "Shared layer found at ${SHARED_ROOT}"
	_log_info "Active version: $(cd "${SHARED_ROOT}" && git describe 2>/dev/null || git rev-parse --short HEAD)"
}

## @brief   Verify script is running from a git repository root
_check_git_root() {
	if ! git rev-parse --show-toplevel &>/dev/null; then
		_log_error "Not inside a git repository. Run from the consuming repo root."
	fi
	local _root _pwd
	_root="$(realpath "$(git rev-parse --show-toplevel)")"
	_pwd="$(realpath "$(pwd)")"
	if [[ "${_pwd}" != "${_root}" ]]; then
		_log_error "Must be run from the repository root: ${_root}"
	fi
	_log_info "Git root confirmed: ${_pwd}"
}

## @brief   Verify script is not being run from inside gitops-agentic-platform itself
_check_not_self() {
	if [[ "$(cd "${SHARED_ROOT}" && git rev-parse --show-toplevel 2>/dev/null)" == "$(pwd)" ]]; then
		_log_error "This script must be run from a CONSUMING repo, not from gitops-agentic-platform itself."
	fi
}

# ── directory helper ──────────────────────────────────────────────────────────

## @brief   Create a directory if it does not already exist
## @param[in]  $1  target directory path
_ensure_dir() {
	local _dir="${1}"
	if [[ ! -d "${_dir}" ]]; then
		mkdir -p "${_dir}"
		_log_info "Created directory: ${_dir}"
	fi
}

# ── copy helpers ──────────────────────────────────────────────────────────────

## @brief   Copy a file from the shared layer into the consuming repo
## @details  Real file copy — not a symlink. Required because Claude Code v2.x
##           file scanning does not follow symlinks. Overwrites existing files
##           so re-running bootstrap always pulls the latest version.
## @param[in]  $1  absolute source path (inside /opt/git/gitops-agentic-platform)
## @param[in]  $2  destination path (inside consuming repo)
_copy_file() {
	local _src="${1}"
	local _dst="${2}"

	if [[ ! -d "$(dirname ${_dst})" ]]; then
		_log_warn "Target directory not found — creating folder path: $(dirname ${_dst})"
		mkdir -p $(dirname ${_dst});
	fi

	if [[ ! -f "${_src}" ]]; then
		_log_warn "Source file not found — skipping: ${_src}"
		return 0
	fi

	if [[ -L "${_dst}" ]]; then
		_log_warn "Replacing stale symlink with real file: ${_dst}"
		rm "${_dst}"
	fi

	cp "${_src}" "${_dst}"
	git add "${_dst}"
	_log_info "Copied: ${_dst} (from ${_src})"
}

## @brief   Deploy skill source files for reference and install runtime skills under $HOME
## @details Claude Code v2.x requires skills to be named SKILL.md and placed
##          inside a named subdirectory under ~/.claude/skills/.
_copy_skills() {
	_ensure_dir "${SKILLS_DIR}"
	_ensure_dir "${HOME}/.claude/skills"

	declare -A _skill_map=(
		["SKILL-global.md"]="global-standards"
		["SKILL-bash.md"]="bash-standards"
		["SKILL-python.md"]="python-standards"
		["SKILL-ansible.md"]="ansible-standards"
		["SKILL-perl.md"]="perl-standards"
	)

	local _f
	for _f in "${SKILL_FILES[@]}"; do
		local _src="${SHARED_ROOT}/.claude/skills/${_f}"
		local _skill_name="${_skill_map[${_f}]}"

		if [[ ! -f "${_src}" ]]; then
			_log_warn "Source not found — skipping: ${_src}"
			continue
		fi

		# project-level flat copy for human reference and auditability
		cp "${_src}" "${SKILLS_DIR}/${_f}"
		git add "${SKILLS_DIR}/${_f}"
		_log_info "Copied skill reference: ${SKILLS_DIR}/${_f}"

		# runtime install for Claude Code scanner
		local _home_skill_dir="${HOME}/.claude/skills/${_skill_name}"
		mkdir -p "${_home_skill_dir}"
		cp "${_src}" "${_home_skill_dir}/SKILL.md"
		sed -i 's/\r//' "${_home_skill_dir}/SKILL.md"
		_log_info "Deployed runtime skill: ${_home_skill_dir}/SKILL.md"
	done
}

## @brief   Copy repository rules into .claude/rules/
_copy_rules() {
	_ensure_dir "${RULES_DIR}"

	local _f
	for _f in "${RULE_FILES[@]}"; do
		_copy_file "${SHARED_ROOT}/.claude/rules/${_f}" "${RULES_DIR}/${_f}"
	done
}

## @brief   Copy all agent files into .claude/agents/ and $HOME/.claude/agents/
_copy_agents() {
	_ensure_dir "${AGENTS_DIR}"
	_ensure_dir "${HOME}/.claude/agents"

	local _f
	for _f in "${AGENT_FILES[@]}"; do
		local _src="${SHARED_ROOT}/.claude/agents/${_f}"
		local _dst="${AGENTS_DIR}/${_f}"

		if [[ ! -f "${_src}" ]]; then
			_log_warn "Source file not found — skipping: ${_src}"
			continue
		fi

		_copy_file "${_src}" "${_dst}"

		if [[ ! -d "$(dirname ${HOME}/.claude/agents/${_f})" ]]; then
			_log_warn "Home directory not found — creating folder path: $(dirname ${HOME}/.claude/agents/${_f})"
			mkdir -p $(dirname ${HOME}/.claude/agents/${_f});
		fi

		cp "${_src}" "${HOME}/.claude/agents/${_f}"
		_log_info "Deployed to HOME: ${HOME}/.claude/agents/${_f}"
	done
}

## @brief   Copy repo-root files (run-agent.sh) from the shared layer
_copy_repo_root_files() {
	local _f
	for _f in "${REPO_ROOT_FILES[@]}"; do
		_copy_file "${SHARED_ROOT}/${_f}" "${_f}"
		chmod 0755 "${_f}"
	done
}

# ── git hook installation ─────────────────────────────────────────────────────

## @brief   Install the post-commit git hook and activate .githooks/
_install_git_hooks() {
	_ensure_dir "${GITHOOKS_DIR}"

	local _hook_src="${SHARED_ROOT}/.githooks/post-commit"
	local _hook_dst="${GITHOOKS_DIR}/post-commit"

	if [[ ! -f "${_hook_src}" ]]; then
		_log_warn "post-commit hook not found in shared layer: ${_hook_src} — skipping"
		return 0
	fi

	cp "${_hook_src}" "${_hook_dst}"
	chmod 0755 "${_hook_dst}"
	git add "${_hook_dst}"
	_log_info "Installed post-commit hook at ${_hook_dst}"

	git config core.hooksPath "${GITHOOKS_DIR}"
	_log_info "git core.hooksPath set to ${GITHOOKS_DIR}"
}

# ── audit directory ───────────────────────────────────────────────────────────

## @brief   Create .claude/audit/ with .gitkeep so the directory is tracked in git
_ensure_audit_dir() {
	_ensure_dir "${AUDIT_DIR}"
	if [[ ! -f "${AUDIT_DIR}/.gitkeep" ]]; then
		touch "${AUDIT_DIR}/.gitkeep"
		git add "${AUDIT_DIR}/.gitkeep"
		_log_info "Created and staged ${AUDIT_DIR}/.gitkeep"
	fi
}

# ── .gitignore ────────────────────────────────────────────────────────────────

## @brief   Patch .gitignore with runtime-only exclusions
_patch_gitignore() {
	local _gitignore=".gitignore"
	local -a _entries=(
		"# gitops-agentic-platform runtime exclusions"
		"static/"
		".claude/vault/"
		"**/*.prom"
		"**/secrets-vault.*"
		"**/.netrc"
		"**/.pgpass"
		"/tmp/gitleaks-report.json"
		"/tmp/trivy-os-report.json"
		"/tmp/trivy-secret-report.json"
		"/tmp/clamscan-report.txt"
		"/tmp/dependency-manifests.txt"
		"/tmp/dependency-audit-raw.txt"
		"/tmp/dependency-audit-files.txt"
		"/tmp/supply-chain-risk.txt"
		"/tmp/priv-esc-risk.txt"
		"/tmp/tempfile-risk.txt"
		"/tmp/refactor-diff.patch"
		"/tmp/refactor-diffstat.txt"
		"/tmp/refactor-status.txt"
		"/tmp/dead-code-files.txt"
		"/tmp/complexity-hints.txt"
		"/tmp/ansible-files.txt"
		"/tmp/ansible-idempotency-hints.txt"
		"/tmp/bash-files.txt"
		"/tmp/bash-strict-hints.txt"
		"/tmp/config-drift-hints.txt"
		"/tmp/repo-structure-dirs.txt"
		"/tmp/repo-structure-files.txt"
		"/tmp/change-impact-status.txt"
		"/tmp/change-impact-diffstat.txt"
		"/tmp/change-impact.patch"
		"/tmp/backward-compat.patch"
		"/tmp/backward-compat-stat.txt"
		"/tmp/runtime-risk-hints.txt"
		"/var/log/rkhunter.log"
	)

	[[ -f "${_gitignore}" ]] || touch "${_gitignore}"

	local _changed=false
	local _entry
	for _entry in "${_entries[@]}"; do
		[[ -z "${_entry}" ]] && continue
		if ! grep -qF "${_entry}" "${_gitignore}"; then
			printf '%s\n' "${_entry}" >> "${_gitignore}"
			_changed=true
		fi
	done

	if ${_changed}; then
		git add "${_gitignore}"
		_log_info "Patched ${_gitignore} with gitops-agentic-platform runtime exclusions."
	else
		_log_warn "${_gitignore} already up to date — skipping."
	fi
}

# ── CLAUDE.md injection ───────────────────────────────────────────────────────

## @brief   Inject the shared-layer reference block into the consuming repo's CLAUDE.md
_patch_claude_md() {
	local _marker="## Shared Configuration Layer"

	if [[ -f "${CLAUDE_MD}" ]] && grep -qF "${_marker}" "${CLAUDE_MD}"; then
		_log_warn "${CLAUDE_MD} already contains shared-layer reference — skipping."
		return 0
	fi

	local _block
	_block=$(cat <<'EOF'

## Shared Configuration Layer

This project uses the gitops-agentic-platform shared Claude Code configuration layer.
Files are copied (not symlinked) from /opt/git/gitops-agentic-platform into .claude/skills/,
.claude/rules/ and .claude/agents/ — real files required for Claude Code v2.x
scanner compatibility.

To update to the latest shared layer version:
  cd /opt/git/gitops-agentic-platform && sudo git pull origin production
  bash /opt/git/gitops-agentic-platform/bootstrap.sh

Active version:
  cd /opt/git/gitops-agentic-platform && git describe

### Skills available (/skills)

| Name | File | Load when |
|---|---|---|
| global-standards | SKILL-global.md | any file |
| bash-standards | SKILL-bash.md | .sh files |
| python-standards | SKILL-python.md | .py files |
| ansible-standards | SKILL-ansible.md | .yml .yaml .j2 files |
| perl-standards | SKILL-perl.md | .pl .pm files |

### Rules available

| Name | Scope |
|---|---|
| global-standards | all files |
| bash-standards | shell scripts |
| python-standards | python files |
| ansible-standards | ansible / yaml / jinja |
| perl-standards | perl files |

### Agents available (/agents)

| Name | Purpose |
|---|---|
| secrets-detection | scan repo for leaked credentials |
| vulnerability-scan | Ubuntu CVE scan + secret scan |
| malware-scan | virus/ransomware scan |
| rootkit-detection | rootkit + misconfiguration check |
| dependency-vulnerability-audit | dependency vulnerability and freshness audit |
| supply-chain-risk | unsafe software supply-chain pattern audit |
| hardcoded-path-risk | hardcoded path and portability audit |
| privilege-escalation-risk | privilege escalation exposure audit |
| unsafe-tempfile-usage | insecure temporary file handling audit |
| refactor-safety-check | refactor safety and behavior drift review |
| dead-code-detection | dead code and stale artifact review |
| complexity-hotspot-detection | complexity and maintainability hotspot review |
| ansible-idempotency-check | rerun safety and idempotency audit |
| bash-strict-mode-check | Bash strict mode and safety audit |
| logging-consistency | logging format and secret leakage review |
| config-drift-detection | configuration drift detection |
| repo-structure-check | repository layout and placement review |
| layering-violation-check | architecture boundary violation review |
| interface-contract-check | internal interface stability review |
| change-impact-assessment | blast radius and impact review |
| backward-compatibility-check | backward compatibility review |
| runtime-risk-estimation | production runtime risk estimate |
| docstring-quality | documentation quality review |
| cli-ux-consistency | CLI ergonomics and consistency review |
| session-audit | write session summary + audit trail |
| checkpoint | pre-push confirmation gate |

### Audit trail

The post-commit git hook reads the Claude session transcript after every
git commit and writes structured log entries to .claude/audit/ automatically.

Activate the hook after every fresh clone:
  git config core.hooksPath .githooks
EOF
)

	if [[ -f "${CLAUDE_MD}" ]]; then
		printf '%s\n' "${_block}" >> "${CLAUDE_MD}"
		_log_info "Appended shared-layer reference block to ${CLAUDE_MD}."
	else
		cat > "${CLAUDE_MD}" <<'STUB'
---
# CLAUDE.md
# TODO: add project-specific knowledge below.
# See /opt/git/gitops-agentic-platform/CLAUDE.md as the full gitops-agentic-platform reference model.
---
STUB
		printf '%s\n' "${_block}" >> "${CLAUDE_MD}"
		_log_info "Created stub ${CLAUDE_MD}."
	fi

	git add "${CLAUDE_MD}"
}

# ── summary ───────────────────────────────────────────────────────────────────

## @brief   Print next-step instructions to the operator
_print_summary() {
	local _version
	_version="$(cd "${SHARED_ROOT}" && git describe 2>/dev/null || git rev-parse --short HEAD)"

	printf '\n'
	_log_info "Bootstrap complete. Shared layer: ${_version}"
	printf '\n'
	printf '  Next steps:\n'
	printf '  1. Complete CLAUDE.md with project-specific knowledge.\n'
	printf '  2. git commit -m "chore: add gitops-agentic-platform shared layer (%s)"\n' "${_version}"
	printf '  3. git push origin <branch>\n'
	printf '\n'
	printf '  On every fresh clone — activate the git hook:\n'
	printf '    git config core.hooksPath .githooks\n'
	printf '\n'
	printf '  To update the shared layer later:\n'
	printf '    cd %s && sudo git pull origin production\n' "${SHARED_ROOT}"
	printf '    bash %s/bootstrap.sh\n' "${SHARED_ROOT}"
	printf '\n'
}

# ── main ──────────────────────────────────────────────────────────────────────

## @brief   Entry point
main() {
	_log_info "${SCRIPT_NAME} starting"

	_check_shared_root
	_check_not_self
	_check_git_root
	_copy_skills
	_copy_rules
	_copy_agents
	_copy_repo_root_files
	_install_git_hooks
	_ensure_audit_dir
	_patch_gitignore
	_patch_claude_md
	_print_summary
}

main "$@"
