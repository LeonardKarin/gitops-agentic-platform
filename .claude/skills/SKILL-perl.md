---
name: perl-standards
description: >
  Perl coding standards for this repository. Covers strict mode usage,
  structured subroutines, safe file handling, reference discipline,
  taint-safe validation, and maintainable Perl patterns.
  Load this skill when generating or modifying .pl or .pm files.
---

<!--
 * @file        SKILL-perl.md
 * @brief       Perl coding standards skill definition
 * @details     Extends global coding standards with Perl-specific best
 *              practices aligned with Perl Best Practices and enterprise
 *              infrastructure scripting conventions.
 * @author      Platform Engineering
 * @compliance  RGPD · FedRAMP
-->

---

## Scope

Applies when generating or reviewing:

Perl scripts (.pl)
Perl modules (.pm)
VMware Perl SDK tooling
legacy infrastructure Perl utilities
automation written in Perl

Extends SKILL-global.md.

Reference:

Perl Best Practices — Damian Conway
perldoc perlstyle

---

## 1. Mandatory Pragmas

Every file must contain:

use strict;
use warnings;

Recommended:

use utf8;
use feature 'say';

Never disable strict globally.

---

## 2. Script Structure

Example layout:

#!/usr/bin/env perl

use strict;
use warnings;

## @file        script_name.pl
## @brief       description
## @details     operational details

### S-GLCR ###
### E-GLCR ###

# constants

# imports

# private subs

# main

main();

---

## 3. Subroutine Design

sub _function_name {

    my ($arg1, $arg2) = @_;

    return $result;
}

Rules:

private subs start with _
explicit parameter unpacking
avoid implicit global usage

---

## 4. References

Use explicit dereferencing:

$ref->{key}
$ref->[0]

Avoid ambiguous syntax.

Prefer structured return values.

---

## 5. File Operations

Always:

open my $fh, '<', $file
    or die "cannot open file";

Never use:

open FH, $file;

Always close:

close $fh;

---

## 6. Error Handling

Use die for fatal errors.

Use warn for recoverable issues.

Check system return codes.

Never suppress errors silently.

---

## 7. External Commands

Prefer:

system("command", "arg");

Avoid:

system("command arg");

Avoid backticks when possible.

---

## 8. Logging

Log intent.

Avoid debug prints.

Never log secrets.

Prefer structured output.

Example:

print "[INFO] connected to $host\n";

---

## 9. Input Validation

Validate:

CLI parameters
API responses
file contents

Never trust external input.

Example:

die "invalid input"
    unless $value =~ /^[0-9]+$/;

---

## 10. VMware Perl SDK Patterns

Always:

check connection status
handle login failure
close sessions
avoid global connection state

---

## 11. Maintainability

Prefer:

small subs
explicit data structures
consistent naming
predictable return types

Avoid:

implicit side effects
deep nested logic
mutable globals

---

## 12. Security Practices

Never:

log credentials
hardcode passwords
disable TLS validation silently
trust user input blindly

Mask sensitive values in logs.

---

## 13. Documentation

Use structured comments:

## @brief
## @param
## @return

Keep documentation aligned with behavior.

---

## 14. Compatibility

Target Perl 5.30+

Avoid experimental syntax.

Avoid deprecated constructs.

---

## 15. Operational Safety

Prefer idempotent logic.

Avoid implicit infrastructure modifications.

Require explicit operator intent for destructive operations.