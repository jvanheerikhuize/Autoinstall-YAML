# Autoinstall YAML

Reproducible, spec-driven **Ubuntu autoinstall configurations** for developer workstations.

https://tinyurl.com/jvh-autoinstall

This repository contains version-controlled [Ubuntu Autoinstall](https://ubuntu.com/server/docs/install/autoinstall-reference) (subiquity) YAML files that provision a developer workstation consistently and without manual intervention — except for the two things that must be per-machine: **network configuration** and **user identity**.

Changes to the configuration are governed by a **spec-based development workflow**: every modification starts with a formal feature specification that must be reviewed and approved before it is implemented.

---

## Quick Deploy

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   Boot Ubuntu Desktop ISO                                        │
│   Press  e  to edit the GRUB entry                               │
│   Find the line starting with  linux                             │
│   Append to the end of that line:                                │
│                                                                  │
│   autoinstall cloud-config-url=https://tinyurl.com/jvh-autoinstall   │
│                                                                  │
│   Press  F10  to boot                                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> The installer fetches the config from the TinyURL above, pauses for **network** and **identity**, then runs completely unattended until reboot.

---

### One-time URL setup

The short URL points to the raw `Autoinstall.yaml` file in this repository. Create it once on [tinyurl.com](https://tinyurl.com) — it never expires:

| Step | Action |
|------|--------|
| 1 | Go to **[tinyurl.com](https://tinyurl.com)** |
| 2 | Paste the long URL: `https://raw.githubusercontent.com/jvanheerikhuize/Autoinstall-YAML/main/Autoinstall.yaml` |
| 3 | Set a custom alias (e.g. `jvh-autoinstall`) |
| 4 | Click **Make TinyURL** |
| 5 | ✓ Done — alias is `jvh-autoinstall` |

> [!TIP]
> TinyURL custom links are free, require no account, and never expire. Use something memorable — you'll type or paste this at the boot prompt.

---

### What happens after you boot

```
  Boot ISO + kernel parameter
           │
           ▼
  Installer fetches Autoinstall.yaml
  from your TinyURL → GitHub raw
           │
     ┌─────▼─────┐    ┌─────────────────┐
     │  Network  │    │    Identity      │
     │ (you act) │    │ hostname + user  │
     │           │    │   (you act)      │
     └─────┬─────┘    └────────┬────────┘
           └──────────────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │  Fully automated:    │
         │  · minimal desktop   │
         │  · LVM storage       │
         │  · dev packages      │
         │  · VS Code snap      │
         │  · UFW firewall      │
         │  · drivers + codecs  │
         │  · all updates       │
         └──────────┬───────────┘
                    │
                    ▼
           Reboot → log in

```

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
Machine reboots  →  Ready to log in
```

---

## Repository Structure

```
├── Autoinstall.yaml                # Active configuration — also served via TinyURL for quick deploy
│
├── specs/
│   ├── features/
│   │   ├── FEAT-0001-ubuntu-developer-workstation.yaml  # approved — base workstation config
│   │   ├── FEAT-0004-automated-locale-timezone.yaml     # approved — locale/keyboard/timezone
│   │   ├── FEAT-0005-openscad-environment.yaml          # draft — OpenSCAD 3D modeling
│   │   ├── FEAT-0006-esp32-development-environment.yaml # draft — ESP32 toolchain
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
| [FEAT-0001](specs/features/FEAT-0001-ubuntu-developer-workstation.yaml) | Ubuntu Developer Workstation Autoinstall | approved |
| [FEAT-0004](specs/features/FEAT-0004-automated-locale-timezone.yaml) | Automated Locale, Keyboard, and Timezone | approved |
| [FEAT-0005](specs/features/FEAT-0005-openscad-environment.yaml) | OpenSCAD 3D Modeling Environment | draft |
| [FEAT-0006](specs/features/FEAT-0006-esp32-development-environment.yaml) | ESP32 Embedded Development Environment | draft |

> `Autoinstall.yaml` is active and implements all approved specs (FEAT-0001, FEAT-0004).

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

The recommended way to test is to boot an Ubuntu Desktop ISO in a virtual machine and use the TinyURL kernel parameter from the Quick Deploy section above.

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
