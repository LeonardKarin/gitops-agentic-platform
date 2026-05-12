# Global repository standards

These rules apply to every file in this repository, regardless of language.

Language-specific rules extend these standards and must not contradict them.

-------------------------------------------------------------------------------

## Encoding and line endings

- All files must use UTF-8 encoding without BOM.
- All files must use Unix LF line endings (\n).
- CRLF (\r\n) is forbidden.
- Every file must end with exactly one newline.
- Trailing whitespace is not allowed.

-------------------------------------------------------------------------------

## Indentation rules

Use the language-native indentation style:

Python:
4 spaces

YAML / Ansible:
2 spaces

JSON:
2 spaces

Markdown:
2 spaces for nested lists

Bash / shell:
tabs

Jinja2:
follow surrounding format

Never mix tabs and spaces in the same file.

-------------------------------------------------------------------------------

## Comment conventions

Documentation structure follows a Doxygen-style logical structure.

The comment delimiter must always match the language syntax.

Never use comment delimiters that are invalid for the language.

Examples:

Python:
docstring or #

Bash:
# or ## prefix

YAML:
# or ## prefix

Jinja2:
{# ... #}

Markdown:
<!-- ... -->

C/C++:
/** ... */

-------------------------------------------------------------------------------

## File header structure

When a file requires structured documentation, use this order:

1. shebang (if applicable)
2. documentation block
3. cartridge placeholder (if used by CI)
4. file content

Example cartridge placeholder:

### S-GLCR ###
### E-GLCR ###

Cartridge values are injected automatically by CI.

Never manually populate cartridge metadata.

-------------------------------------------------------------------------------

## Naming conventions

files:
snake_case

directories:
snake_case or kebab-case

environment variables:
SCREAMING_SNAKE_CASE

constants:
SCREAMING_SNAKE_CASE

Python functions:
snake_case

Python classes:
PascalCase

Bash functions:
_snake_case for private helpers

Ansible variables:
snake_case

Names must be descriptive and consistent across modules.

Avoid abbreviations unless they are widely understood.

-------------------------------------------------------------------------------

## Secrets and confidential data

Never store secrets in tracked files.

Secrets include:

passwords
API tokens
private keys
session tokens
vault material
customer confidential data

Secrets must be retrieved from:

CI/CD masked variables
vault tooling
environment variables
runtime secret providers

Never log secrets or raw confidential payloads.

Sensitive outputs must be treated as confidential until reviewed.

-------------------------------------------------------------------------------

## General quality expectations

All generated code must be:

readable
deterministic
minimal
safe
production-appropriate

Avoid:

dead code
commented-out legacy blocks
unused imports
debug print statements
hidden side effects

Prefer explicit and maintainable logic over clever shortcuts.

-------------------------------------------------------------------------------

## Relationship with language-specific rules

Language-specific rules may define:

formatting standards
typing requirements
lint expectations
architectural constraints

Language-specific rules extend this document but must not contradict it.