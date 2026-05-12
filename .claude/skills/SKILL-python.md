---
name: python-standards
description: Use this skill when generating, editing, reviewing, or refactoring Python code in this repository. Applies repository Python conventions including PEP 8, Doxygen-style docstrings, type annotations, aggregator/FSM patterns, threading safety, and confidential credential handling.
---

# Python Standards Skill

Use this skill for Python-focused work when a deeper repository-aware review or generation pass is needed.

This skill complements the repository rule for `*.py` files. The rule provides the baseline behavior. This skill adds extra review depth for architecture, security, and project conventions.

## Objectives

- Generate Python code that is clean, readable, and Python 3.8+ compatible.
- Follow repository conventions for structure, typing, documentation, logging, and threading.
- Respect project-specific patterns for aggregators, FSM flows, vault-backed secrets, and static output generation.
- Avoid leaking confidential information in logs, debug output, or persisted state.

## Baseline standards

- Follow PEP 8.
- Use 4 spaces, never tabs.
- Keep code lines at 99 characters max.
- Keep comments and docstrings at 79 characters max.
- Group imports as stdlib, third-party, local.
- Never use wildcard imports.
- Use type annotations on public APIs.
- Prefer `Optional[T]` over `T | None`.
- Prefer `pathlib.Path` for new filesystem code.
- Use specific exceptions.
- Never use bare `except:`.

## Documentation style

Use Python docstrings for public modules, classes, and functions.

When documenting public code, use Doxygen-style tags inside the docstring, for example:

```python
def get_host_facts(hostname: str, timeout: int = 30) -> dict:
    """
    @brief   Retrieve host facts for a hostname.
    @param[in]   hostname   Target host FQDN
    @param[in]   timeout    Request timeout in seconds
    @return  dict
    @throws  ValueError
    """