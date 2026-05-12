---
description: >
  Perl coding standards for this repository. Covers strict mode enforcement,
  warnings discipline, structured subroutine design, safe file handling,
  taint-safe practices, and operational maintainability conventions.
  Automatically applies when modifying or generating any .pl or .pm file.
globs:
  - "**/*.pl"
  - "**/*.pm"
alwaysApply: true
---

# Perl Standards

## Scope

Applies to all Perl files:

.pl scripts
.pm modules
Perl-based tooling
Perl automation scripts
VMware SDK Perl scripts
legacy infrastructure Perl utilities

All rules extend global-standards.md.

Reference:

Perl Best Practices — Damian Conway
perldoc perlstyle

---

## 1. Required Pragmas

Every Perl file MUST begin with:

use strict;
use warnings;

Optional but recommended:

use feature 'say';
use utf8;

Never disable strict or warnings globally.

---

## 2. File Header Structure

Each file must begin with structured metadata:

## @file        script_name.pl
## @brief       One-line description
## @details     Functional overview, runtime assumptions, dependencies
## @author      Name / Team
## @date        YYYY-MM-DD
## @note        Classification: INTERNAL | CONFIDENTIAL

Example:

#!/usr/bin/env perl

use strict;
use warnings;

## @file        inventory_sync.pl
## @brief       Synchronizes ESXi host inventory
## @details     Queries vSphere API and aggregates host metrics
## @author      Platform Engineering
## @note        Classification: INTERNAL

---

## 3. Variable Naming

### Conventions

| type | prefix | example |
|------|--------|--------|
| scalar | $ | $host_name |
| array | @ | @host_list |
| hash | % | %host_map |
| reference | $ | $config_ref |

Use snake_case for identifiers.

Avoid:

camelCase
Hungarian notation
single-letter variables except loop indexes

---

## 4. Subroutine Structure

All subs must:

be declared explicitly
return predictable structures
avoid implicit globals

Example:

sub _compute_cluster_count {
    my ($cluster_ref) = @_;

    return scalar keys %{$cluster_ref};
}

Guidelines:

private subs start with _
public entrypoints may omit _
avoid side effects unless explicitly documented

---

## 5. Argument Handling

Prefer explicit unpacking:

my ($host, $user, $password) = @_;

Avoid:

shift without documentation
implicit @_ indexing

Document expected parameters:

## @param[in] $host hostname
## @param[in] $user username

---

## 6. Hash and Reference Safety

Always dereference explicitly:

$host_ref->{name}

Avoid ambiguous dereferencing.

Preferred:

my %config = %{ $config_ref };

Avoid modifying shared references without intention.

---

## 7. Error Handling

Use die for unrecoverable errors:

die "Missing host parameter";

Use eval blocks for controlled exception handling:

eval {
    risky_operation();
};

if ($@) {
    warn "Operation failed: $@";
}

Never suppress errors silently.

---

## 8. File Handling

Always use lexical filehandles:

open my $fh, '<', $file
    or die "Cannot open $file: $!";

Avoid bareword filehandles.

Always close explicitly:

close $fh;

Use three-argument open.

Never rely on implicit open behavior.

---

## 9. Module Imports

Import only required symbols.

Example:

use VMware::VIRuntime;

Avoid wildcard imports where possible.

Group imports at top of file.

---

## 10. Data Structures

Prefer hashrefs and arrayrefs for structured returns.

Example:

return {
    host => $host_name,
    status => $status
};

Avoid returning unstructured lists when meaning matters.

---

## 11. Logging

Logging should be explicit and structured.

Example:

print "[INFO] connected to $host\n";

Avoid debug prints left in production code.

Sensitive data must never be printed.

Avoid printing credentials or tokens.

---

## 12. Taint Safety

Never trust external input.

Validate:

CLI arguments
environment variables
external file input
API responses

Example:

die "invalid hostname"
    unless $host =~ /^[a-z0-9\-\.]+$/;

---

## 13. External Command Execution

Prefer system with explicit arguments:

system("ls", "-l");

Avoid:

system("ls -l");

Avoid backticks when system is sufficient.

Check exit codes:

system("command") == 0
    or die "command failed";

---

## 14. VMware SDK Perl

When using VMware Perl SDK:

Always validate session connection.
Avoid global connection state.
Close sessions explicitly.
Handle connection failures gracefully.

---

## 15. Formatting

Indent with 4 spaces.

No tabs.

Opening brace on same line:

if (...) {

Closing brace aligned with statement start.

Example:

if ($condition) {
    do_something();
}

---

## 16. Security Rules

Never log credentials.
Never hardcode passwords.
Never disable SSL verification silently.
Never trust external input blindly.

Sensitive data must be masked.

---

## 17. Documentation Blocks

Use Doxygen-style comments.

Example:

## @brief   retrieves ESXi host version
## @param[in] $host_ref reference to host object
## @return version string

Place directly above sub definition.

---

## 18. Operational Safety

Avoid destructive operations without confirmation.

Avoid modifying infrastructure state implicitly.

Scripts should be idempotent where possible.

Avoid modifying remote systems without explicit operator intent.

---

## 19. Compatibility

Target Perl version:

5.30+

Avoid deprecated constructs.

Avoid experimental syntax unless required.

---

## 20. Forbidden Patterns

no strict;
no warnings;
bareword filehandles
implicit globals
backticks for complex pipelines
hardcoded credentials
eval without error check
global mutable state