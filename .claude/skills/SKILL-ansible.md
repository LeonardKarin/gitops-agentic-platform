---
name: ansible-standards
description: Use this skill when generating, reviewing, or refactoring Ansible, YAML, or Jinja2 files. Ensures YAML 1.2 compliance, FQCN module usage, idempotent playbooks, safe variable handling, and predictable templating patterns.
---

# Ansible Standards Skill

Use this skill when working with:

Ansible playbooks
task files
handler files
inventory YAML
vars files
Jinja2 templates

This skill enforces repository conventions for YAML formatting, Ansible structure,
idempotency, and templating safety.

-------------------------------------------------------------------------------

## Objectives

Ensure generated Ansible content is:

valid YAML 1.2.2
idempotent
readable
safe
compatible with existing repository conventions

Avoid ambiguous syntax or implicit behavior.

-------------------------------------------------------------------------------

## YAML structure

Indentation must use 2 spaces.

Tabs are forbidden.

Files must begin with:

---

Maintain consistent indentation depth.

Avoid trailing whitespace.

-------------------------------------------------------------------------------

## Module naming

Always use Fully Qualified Collection Names.

Example:

ansible.builtin.copy
ansible.builtin.template
ansible.builtin.file
ansible.builtin.service
ansible.builtin.apt

Avoid short-form module names.

-------------------------------------------------------------------------------

## Boolean values

Use:

true
false

Avoid:

yes
no
True
False

-------------------------------------------------------------------------------

## Task design

Tasks must be:

explicit
idempotent
predictable

Always specify state when applicable.

Example:

state: present
state: latest

Task names must describe the action and target.

-------------------------------------------------------------------------------

## Variables

Variables must use snake_case.

Avoid camelCase.

Sensitive values must not be hardcoded.

Use vault or runtime secret providers.

Example:

db_password: "{{ vault_db_password }}"

Avoid exposing secrets in debug output.

-------------------------------------------------------------------------------

## Template usage

Use correct Jinja2 syntax.

Output:

{{ variable }}

Control flow:

{% if %}
{% for %}

Comments:

{# comment #}

Use filters appropriately:

default
replace
int
combine

Avoid overly complex inline logic.

-------------------------------------------------------------------------------

## Template whitespace control

Use trimming markers when needed:

{%- -%}

Avoid producing unnecessary blank lines.

-------------------------------------------------------------------------------

## Handlers

Notify handlers by name.

Reuse shared handlers when possible.

Avoid duplicating handler definitions.

-------------------------------------------------------------------------------

## Inventory awareness

Respect repository inventory structure.

Avoid modifying generated inventory files.

Maintain predictable host targeting patterns.

-------------------------------------------------------------------------------

## Expected output quality

Generated Ansible files must:

run without YAML parsing errors
avoid deprecated syntax
avoid ambiguous module resolution
avoid implicit behavior

Prefer clarity over cleverness.

-------------------------------------------------------------------------------

## Relationship with global standards

Global standards apply first.

Ansible-specific rules extend global conventions.

Do not violate encoding, naming, or security requirements defined globally.