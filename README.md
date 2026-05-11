# gitops-agentic-platform

> Enterprise-grade agentic AI platform built on GitOps principles.  
> Secure, auditable, and compliant Claude Code deployments across infrastructure repositories.

---

## Overview

This platform provides a production-ready framework for deploying AI agents (Claude Code) across infrastructure repositories using GitOps principles.

It solves a problem most enterprises haven't tackled yet: **how do you deploy AI agents in production in a way that is secure, traceable, compliant, and operationally sound?**

Key design principles:
- **Immutability** — every agent action produces an immutable audit trail
- **Security-first** — CVE pre-checks before any tool installation
- **Compliance-ready** — FedRAMP control mappings out of the box
- **GitOps-native** — the platform itself is version-controlled and auditable

---

## Architecture

```text
gitops-agentic-platform/
├── shared/
│   ├── rules/
│   ├── skills/
│   └── agents/
│       ├── security/
│       ├── audit/
│       ├── quality/
│       ├── infra/
│       └── workflow/
├── bootstrap/
│   └── bootstrap.sh
├── hooks/
│   └── post-commit
├── pipelines/
│   └── validate.yml
└── docs/
    └── compliance/
```

---

## Core Components

### Shared Layer
The shared layer is the heart of the platform. It defines:
- **Rules** — path-scoped behavioral constraints for agents
- **Skills** — reusable knowledge modules injected as context
- **Agents** — categorized by domain (security, audit, quality, infra, workflow)

The shared layer is distributed to all consumer repositories via `bootstrap.sh`, ensuring consistency across the entire infrastructure fleet.

### Security Pipeline

```text
Tool installation request
        ↓
CVE pre-check (NVD → CISA KEV → OSV → EPSS)
        ↓
CVSS score evaluation (blocks on ≥ 7.0)
        ↓
CISA KEV match check (immediate block)
        ↓
Secrets detection scan
        ↓
Supply chain risk validation
        ↓
Proceed or Block
```

### Immutable Audit Trail

```text
Post-commit hook
        ↓
Extract Claude transcript
        ↓
Sanitize credentials and PII
        ↓
Structure by exchange
        ↓
Map to FedRAMP controls (CM-3, AU-2, AU-3, AU-9)
        ↓
Append to immutable audit store
```

### Bootstrap Distribution

```bash
./bootstrap/bootstrap.sh
```

Distributes the shared layer to all registered consumer repositories.  
Handles symlink vs real file detection (Claude Code v2.x compatibility).  
Supports semantic versioning with git tags.

---

## FedRAMP Control Mappings

| Control | Description | Implementation |
|---|---|---|
| CM-3 | Configuration Change Control | Post-commit audit trail on every agent action |
| CM-6 | Configuration Settings | Path-scoped rules enforcement |
| AU-2 | Audit Events | Structured logging of all agent interactions |
| AU-3 | Content of Audit Records | Exchange-level transcript capture |
| AU-9 | Protection of Audit Information | Immutable append-only audit store |
| IA-5 | Authenticator Management | Secrets detection pre-check |
| SI-2 | Flaw Remediation | CVE pre-check against NVD/CISA KEV |
| SI-3 | Malware Protection | Supply chain risk validation |
| IR-4 | Incident Handling | Automated blocking on critical CVEs |

---

## Security Agents

### CVE Pre-Check
Queries multiple vulnerability databases before any tool installation:
- **NVD** (National Vulnerability Database)
- **CISA KEV** (Known Exploited Vulnerabilities)
- **OSV** (Open Source Vulnerabilities)
- **EPSS** (Exploit Prediction Scoring System)

Blocking criteria:
- CVSS score ≥ 7.0
- Any CISA KEV match
- Critical OSV advisory

### Secrets Detection
Scans all agent-generated content for:
- API keys and tokens
- Private keys and certificates
- Database credentials
- Cloud provider credentials

### Supply Chain Risk Validation
Validates third-party dependencies and tools against known supply chain compromise indicators before agent-assisted installation.

### Ansible Idempotency Check
Analyzes Ansible playbooks for non-idempotent patterns:
- `command`/`shell` modules without `creates`/`removes` guards
- Missing handlers and notify directives
- Tasks that would re-execute unnecessarily

### Config Drift Detection
Detects configuration drift between declared state and actual infrastructure state before agent-assisted remediation.

---

## Getting Started

### Prerequisites
- Claude Code installed and configured
- Git repository with standard structure
- Bash 4.0+

### Bootstrap

```bash
# Clone the platform
git clone https://github.com/LeonardKarin/gitops-agentic-platform.git

# Bootstrap to a consumer repository
cd gitops-agentic-platform
./bootstrap/bootstrap.sh --target /path/to/your/repo

# Verify installation
ls /path/to/your/repo/.claude/
```

### Configuration

```bash
# Copy example configuration
cp .env.example .env

# Edit with your settings
vim .env
```

---

## Design Decisions

**Why GitOps?**  
GitOps gives us version control, peer review, and audit trail for free. Every change to agent behavior is a commit — reviewable, reversible, traceable.

**Why immutable audit trails?**  
In regulated environments, you need to prove what happened. An agent that leaves no trace is an agent you cannot trust in production.

**Why FedRAMP controls?**  
FedRAMP provides a well-defined, internationally recognized control framework. Mapping agent operations to FedRAMP controls makes the platform compliance-ready for enterprise and government environments.

**Why block on CVSS ≥ 7.0?**  
This threshold aligns with industry standard "High" severity classification. In production infrastructure, a High or Critical CVE in an agent-installed tool is an unacceptable risk.

---

## Roadmap

- [ ] Kubernetes-native deployment
- [ ] Multi-agent orchestration patterns
- [ ] SIEM integration (Splunk, Elastic)
- [ ] SOC2 Type II control mappings
- [ ] Terraform provider for platform provisioning
- [ ] Web dashboard for audit trail visualization

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built by a Principal Engineer who operates production infrastructure at scale  
and believes that AI agents in production require the same rigor as any other production system.*
