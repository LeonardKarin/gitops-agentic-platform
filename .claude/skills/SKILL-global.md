---
name: global-standards
description: Apply repository-wide coding standards when generating, reviewing, or refactoring any file. Covers encoding rules, comment conventions, naming standards, cartridge header structure, and secure handling of confidential data.
---

# Global Standards Skill

Use this skill when producing or reviewing any file in this repository.

This skill ensures consistency across all languages and prevents violations of repository-wide conventions.

The goal is predictable, compliant, production-ready code.

-------------------------------------------------------------------------------

## Core expectations

All generated files must:

use UTF-8 encoding without BOM
use LF line endings
end with exactly one newline
contain no trailing whitespace
follow consistent naming conventions
avoid embedding secrets
respect language-native syntax rules

Never introduce formatting that conflicts with repository conventions.

-------------------------------------------------------------------------------

## Documentation structure

Documentation blocks follow a Doxygen-style logical structure.

The documentation syntax must always respect the native comment delimiter of the language.

Examples:

Python:

"""
@brief   Short description
@details Extended explanation
"""

Bash:

## @brief   Short description
## @details Extended explanation

YAML:

## @brief   Short description
## @details Extended explanation

Markdown:

<!--
@brief   Short description
-->

Use structured documentation only where useful.

Avoid excessive verbosity.

-------------------------------------------------------------------------------

## Cartridge placeholder rules

If the repository uses cartridge metadata blocks, preserve the placeholder:

### S-GLCR ###
### E-GLCR ###

Do not modify cartridge metadata manually.

Do not invent values.

CI manages cartridge content.

-------------------------------------------------------------------------------

## Naming consistency

Respect naming conventions:

snake_case for files
PascalCase for classes
SCREAMING_SNAKE_CASE for constants
descriptive variable names
no cryptic abbreviations

Naming must remain consistent across modules.

-------------------------------------------------------------------------------

## Security requirements

Never expose secrets in:

logs
debug output
config files
generated artifacts

Never hardcode credentials.

Never serialize confidential runtime values into tracked files.

When handling confidential data:

minimize exposure
minimize lifetime
avoid unnecessary persistence

-------------------------------------------------------------------------------

## Output expectations

Generated content must:

integrate cleanly into the repository
respect formatting conventions
avoid unnecessary refactoring noise
preserve existing structure unless change is required
avoid introducing unrelated changes

Prefer minimal diff changes when editing existing files.

-------------------------------------------------------------------------------

## When reviewing files

Verify:

encoding consistency
absence of trailing whitespace
naming consistency
absence of secrets
correct comment syntax for the language
cartridge placeholder preserved if present

Reject patterns that introduce risk or inconsistency.

-------------------------------------------------------------------------------

## Relationship with language-specific skills

Language-specific skills extend this skill.

Examples:

python-standards
bash-standards
ansible-standards

Global standards always apply first.