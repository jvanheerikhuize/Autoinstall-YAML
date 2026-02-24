# Autoinstall YAML

Reproducible, spec-driven **Ubuntu autoinstall configurations** for developer workstations.

This repository contains version-controlled [Ubuntu Autoinstall](https://ubuntu.com/server/docs/install/autoinstall-reference) (subiquity) YAML files that provision a developer workstation consistently and without manual intervention — except for the two things that must be per-machine: **network configuration** and **user identity**.

Changes to the configuration are governed by a **spec-based development workflow**: every modification starts with a formal feature specification that must be reviewed and approved before it is implemented.

---

## How It Works

```
Boot Ubuntu ISO  →  Network config (interactive)  →  Identity config (interactive)
        ↓
Automated installation:
  • ubuntu-desktop-minimal base
  • LVM storage layout
  • Developer packages (git, curl, build-essential, …)
  • VS Code (snap)
  • UFW firewall enabled
  • Third-party drivers + codecs
  • All updates applied
        ↓
Machine powers off  →  Ready for first boot
```

---

## Repository Structure

```
├── Autoinstall.yaml                # Active configuration (created when FEAT-0001 is approved)
├── Autoinstall.example.yaml        # Reference example — format reference only
│
├── specs/
│   ├── features/
│   │   ├── FEAT-0001-ubuntu-developer-workstation.yaml  # Active spec
│   │   └── _template.yaml                               # Template for new specs
│   └── schemas/
│       └── feature-spec.schema.json                     # Spec validation schema
│
├── specs.config.yaml               # Central spec registry
│
├── .ai/                            # AI assistant context
│   ├── CONTEXT.md                  # Project context (AI starts here)
│   ├── config.yaml                 # AI behavior configuration
│   ├── specs/SPEC.md               # Product specification
│   └── architecture/
│       ├── ARCHITECTURE.md         # How the autoinstall system is structured
│       └── PATTERNS.md             # YAML conventions
│
├── .claude/
│   └── CLAUDE.md                   # Claude Code instructions
│
├── docs/
│   ├── spec-based-development.md   # Spec workflow guide
│   └── runbooks/                   # Operational procedures
│
└── scripts/
    ├── ingest-spec.sh              # Bash: process a spec with an AI CLI
    └── Invoke-SpecIngestion.ps1    # PowerShell: same, for Windows
```

---

## Current Status

| Spec | Title | Status |
|------|-------|--------|
| [FEAT-0001](specs/features/FEAT-0001-ubuntu-developer-workstation.yaml) | Ubuntu Developer Workstation Autoinstall | draft |

> `Autoinstall.yaml` will be created once FEAT-0001 is approved and implemented.

---

## Spec-Based Workflow

All changes to the autoinstall configuration follow this process:

```
1. Draft a spec in specs/features/FEAT-XXXX-<name>.yaml
2. Submit for review → set status: review
3. Approve → set status: approved
4. Implement → create/update Autoinstall.yaml
5. Test in a VM
6. Merge → set status: implemented
```

### Creating a New Spec

Copy the template and fill in the required fields:

```bash
cp specs/features/_template.yaml specs/features/FEAT-0002-my-feature.yaml
```

Required fields: `metadata.id`, `metadata.title`, `metadata.version`, `metadata.status`, `description.summary`, `description.problem_statement`, `description.proposed_solution`, and at least one entry in `acceptance_criteria`.

### Implementing a Spec (AI-assisted)

```bash
# Bash/Unix — process an approved spec with AI
./scripts/ingest-spec.sh specs/features/FEAT-0001-ubuntu-developer-workstation.yaml

# PowerShell — same, for Windows
./scripts/Invoke-SpecIngestion.ps1 -SpecFile specs/features/FEAT-0001-ubuntu-developer-workstation.yaml
```

---

## Testing the Autoinstall YAML

The recommended way to test is to boot an Ubuntu Desktop ISO in a virtual machine and pass the `Autoinstall.yaml` via the subiquity `autoinstall` kernel parameter or a `user-data` file on a cloud-init data source.

```bash
# Example: serve the YAML over HTTP and boot with:
#   autoinstall ds=nocloud-net;s=http://<your-ip>/
```

After installation, verify:
- All packages in the spec are present
- Snaps are installed (`snap list`)
- UFW is active (`sudo ufw status`)
- User account exists with sudo
- Machine was configured with LVM (`sudo vgs`)

---

## AI Assistant Setup

This repository is configured for AI-assisted development. Any AI coding assistant can use the context in `.ai/`:

| File | Purpose |
|------|---------|
| [.ai/CONTEXT.md](.ai/CONTEXT.md) | Project overview — AI reads this first |
| [.ai/specs/SPEC.md](.ai/specs/SPEC.md) | Product specification |
| [.ai/architecture/ARCHITECTURE.md](.ai/architecture/ARCHITECTURE.md) | How the autoinstall system is structured |
| [.ai/architecture/PATTERNS.md](.ai/architecture/PATTERNS.md) | YAML conventions |
| [.ai/config.yaml](.ai/config.yaml) | AI behavior preferences |

Claude Code users: the `.claude/CLAUDE.md` file is auto-loaded and instructs Claude to read these context files first.

---

## Author

**Jerry van Heerikhuize** ([@jvanheerikhuize](https://github.com/jvanheerikhuize))

---

## References

- [Ubuntu Autoinstall Reference](https://ubuntu.com/server/docs/install/autoinstall-reference)
- [Ubuntu Autoinstall Quick Start](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Subiquity on GitHub](https://github.com/canonical/subiquity)
