---
paths:
  - "**/*.yml"
  - "**/*.yaml"
  - "**/*.j2"
---

# Ansible, YAML and Jinja2 standards

These rules apply to all Ansible playbooks, task files, variable files, handlers,
inventories, and Jinja2 templates.

These rules extend global-standards.md and must not contradict it.

-------------------------------------------------------------------------------

## YAML formatting

Indentation:
2 spaces per level

Tabs are forbidden in YAML files.

Each playbook must begin with the YAML document marker:

---

Example:

---
- name: Example playbook

Use consistent indentation depth across the entire file.

Avoid trailing spaces.

-------------------------------------------------------------------------------

## Comments

Use language-native comment syntax.

Doxygen-style structure is allowed but must use YAML-compatible delimiters.

Use:

## for structured documentation blocks
# for inline comments

Example file header:

## @file        playbook_name.yaml
## @brief       One-line summary
## @details     Extended explanation of purpose and scope
## @note        Classification: INTERNAL
---

Never use:

// or /* */

These are invalid YAML syntax.

-------------------------------------------------------------------------------

## Booleans

Use lowercase YAML 1.2.2 booleans only:

true
false

Never use:

yes
no
True
False

Example:

become: true
ignore_errors: false

-------------------------------------------------------------------------------

## Strings

Prefer unquoted strings unless special characters require quoting.

Quote strings containing:

:
{
}
[
]
,
#
|
>
!
%
@
`

Example:

msg: "Error: package not found"

Use block scalars for multiline content:

script: |
  #!/usr/bin/env bash
  echo hello

-------------------------------------------------------------------------------

## FQCN module usage

Always use Fully Qualified Collection Names for modules.

Correct:

ansible.builtin.copy
ansible.builtin.template
ansible.builtin.file
ansible.builtin.service
ansible.builtin.apt

Incorrect:

copy
template
file
service
apt

FQCN avoids ambiguity and ensures deterministic execution.

-------------------------------------------------------------------------------

## Playbook structure

Minimal structure:

- name
  hosts
  become
  gather_facts
  vars
  roles
  tasks
  post_tasks

Example:

- name: Example campaign
  hosts: "{{ limit | default('all') }}"
  become: true
  gather_facts: true

  vars:
    campaign: example

  roles:
    - role: global_handlers

  tasks:
    - name: Import task file
      ansible.builtin.import_tasks: tasks/example.yaml

-------------------------------------------------------------------------------

## Task naming

Task names must be descriptive and human-readable.

Correct:

- name: Install openssh-server at patched version

Incorrect:

- name: Install package

Task names must describe:

action
target
intent

-------------------------------------------------------------------------------

## Idempotency

All tasks must be idempotent.

Always define explicit state.

Correct:

state: present
state: absent
state: latest
state: started
state: stopped

Avoid tasks that change state implicitly.

-------------------------------------------------------------------------------

## Variables

Use snake_case for all variable names.

Prefix project-specific variables when appropriate.

Example:

plw_nas_host
campaign_folder
plw_retention_days

Avoid camelCase or mixedCase.

-------------------------------------------------------------------------------

## Sensitive data

Never hardcode credentials.

Sensitive data must come from:

Ansible Vault
environment variables
runtime secret providers
external vault tooling

Incorrect:

db_password: "secret"

Correct:

db_password: "{{ vault_db_password }}"

Never print secrets in debug output.

-------------------------------------------------------------------------------

## Handlers

Handlers must be referenced by name.

Do not duplicate handler definitions across playbooks.

Example:

notify: Restart sshd

Handlers should live in shared roles when possible.

-------------------------------------------------------------------------------

## Inventory

Inventory files generated automatically must not be manually edited.

Examples:

per_*.yaml
rd_*.json
rd_root_level.json

Group naming should remain consistent.

Example:

dc_environment_platform

prod_enterprise
sg1_dev_orchestra

-------------------------------------------------------------------------------

## Scope limitation

Always support execution scope via limit.

Example:

hosts: "{{ limit | default('all') }}"

Avoid playbooks that implicitly target all environments without control.

-------------------------------------------------------------------------------

## Jinja2 templates

Use correct delimiters:

{{ variable }} for output

{% control structures %}

{# comments #}

Example:

- job_name: node_{{ inventory_hostname }}

Use filters when appropriate:

{{ variable | default('value') }}

Avoid complex inline logic.

Keep templates readable and predictable.

-------------------------------------------------------------------------------

## Whitespace control in Jinja2

Use trimming syntax when necessary:

{%- for host in groups['example'] %}
  - {{ host }}
{%- endfor %}

Avoid generating unintended blank lines.

-------------------------------------------------------------------------------

## Campaign output

Campaign logs must use the provided variable:

{{ campaign_folder }}

Never construct campaign paths manually.

Avoid hardcoded filesystem paths when a variable is available.

-------------------------------------------------------------------------------

## General expectations

Playbooks must be:

idempotent
readable
deterministic
safe for repeated execution

Avoid:

implicit side effects
ambiguous module usage
hardcoded environment assumptions