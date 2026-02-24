# Project Context

> **For AI Assistants**: This is the master context file. Start here for a complete understanding of the project.

<!--
  AI PROCESSING INSTRUCTIONS:
  1. Read this file first to understand project scope
  2. Follow links to detailed documents as needed
  3. Check config.yaml for behavior preferences
  4. Respect patterns in architecture/PATTERNS.md
-->

## Quick Reference

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPEC.md](specs/SPEC.md) | Product requirements | Understanding WHAT to build |
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | System design | Understanding HOW it's structured |
| [PATTERNS.md](architecture/PATTERNS.md) | YAML conventions | Writing or reviewing autoinstall YAML |
| [decisions/](decisions/) | ADRs | Understanding WHY decisions were made |

---

## 1. Project Summary

### Identity
- **Name**: Autoinstall YAML
- **Type**: Configuration — Ubuntu subiquity autoinstall YAML
- **Stage**: Greenfield
- **Author**: Jerry van Heerikhuize ([@jvanheerikhuize](https://github.com/jvanheerikhuize))

### One-Liner
> Reproducible, spec-driven Ubuntu autoinstall YAML configurations for developer workstations, managed through a formal spec-based development workflow.

### Developer Domains
| Domain | Tools | Status |
|--------|-------|--------|
| JavaScript / Node.js | nodejs, npm, VS Code | Implemented (FEAT-0001) |
| 3D modeling / CAD | OpenSCAD | Spec planned (FEAT-0005) |
| ESP32 / embedded | esptool, python3-serial, minicom, Arduino IDE, dialout group | Spec planned (FEAT-0006) |

### Target Hardware
| Component | Detail |
|-----------|--------|
| Machine | Dell Inc. Latitude 5400 |
| CPU | Intel 8th Gen Whiskey Lake (i5-8265U / i7-8665U) |
| GPU | Intel UHD Graphics 620 |
| Wi-Fi | Intel Wireless-AC 9560 (iwlwifi + linux-firmware) |
| Audio | Realtek ALC256 (requires sof-firmware + alsa-ucm-conf) |
| Fingerprint | Broadcom BCM58200 (handled via OEM stack) |
| Thunderbolt | Thunderbolt 3 (managed by bolt) |
| Firmware | Dell LVFS support via fwupd + fwupd-signed |

### Tech Stack
| Layer | Technology |
|-------|------------|
| Configuration format | YAML (Ubuntu Autoinstall / subiquity) |
| Installer | Ubuntu subiquity (24.04 LTS+) |
| Storage backend | curtin (via `curtin in-target`) |
| Package management | APT + Snap |
| Spec format | YAML (feature-spec.schema.json) |
| Automation | GitHub Actions, Bash, PowerShell |

---

## 2. Current State

### Active Work
- [x] FEAT-0001: Ubuntu Developer Workstation Autoinstall — approved, implemented in Autoinstall.yaml
- [x] FEAT-0004: Automated Locale, Keyboard, Timezone — approved, implemented in Autoinstall.yaml
- [ ] FEAT-0005: OpenSCAD Environment — draft, pending approval
- [ ] FEAT-0006: ESP32 Development Environment — draft, pending approval

### Recent Changes
- 2026-02-24: Implemented Autoinstall.yaml from FEAT-0001 (base workstation) and FEAT-0004 (locale/timezone)
- 2026-02-24: Added Dell Latitude 5400 hardware support packages (AC-016–AC-020)
- 2026-02-24: Added Node.js/npm (AC-021), OpenSCAD spec (FEAT-0005), ESP32 spec (FEAT-0006)

### Known Issues
- FEAT-0005 and FEAT-0006 are in draft — review and approve before implementing

---

## 3. Key Concepts

### Domain Model
```
[Ubuntu ISO] ──boot──► [subiquity installer]
                              │
                         reads YAML
                              │
                   ┌──────────▼──────────┐
                   │  Autoinstall.yaml   │
                   │  ┌───────────────┐  │
                   │  │  source       │  │  ← ubuntu-desktop-minimal
                   │  │  storage      │  │  ← LVM layout
                   │  │  packages     │  │  ← dev tools + security
                   │  │  snaps        │  │  ← VS Code, security center
                   │  │  late-commands│  │  ← post-install scripts
                   │  └───────────────┘  │
                   └──────────┬──────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Installed Ubuntu  │
                    │  Developer         │
                    │  Workstation       │
                    └───────────────────┘
```

### Bounded Contexts
| Context | Responsibility | Key YAML Sections |
|---------|---------------|-------------------|
| Base system | OS source and installer update | `source`, `refresh-installer`, `oem` |
| Identity | User account and hostname | `identity` (interactive) |
| Networking | Network configuration | `network` (interactive) |
| Storage | Disk layout | `storage` |
| Software | Packages and snaps | `packages`, `snaps` |
| Security | Firewall and drivers | `debconf-selections`, `drivers`, `codecs` |
| Post-install | Late commands (chroot) | `late-commands` |
| Updates | APT mirror and update policy | `apt`, `updates` |

### Critical Paths
1. **Installation flow**: ISO boot → subiquity reads YAML → interactive network → interactive identity → automated installation → late-commands → reboot
2. **Spec flow**: Draft spec → review → approve → implement YAML → validate → merge

---

## 4. Codebase Navigation

### Entry Points
| Purpose | Location |
|---------|----------|
| Active autoinstall config | `Autoinstall.yaml` |
| Active feature spec | `specs/features/FEAT-0001-ubuntu-developer-workstation.yaml` |
| Spec registry | `specs.config.yaml` |

### Key Files
```
Autoinstall.yaml               # Active config — implements FEAT-0001 + FEAT-0004
specs/
├── features/
│   ├── FEAT-0001-ubuntu-developer-workstation.yaml  # approved — base workstation
│   ├── FEAT-0004-automated-locale-timezone.yaml     # approved — locale/keyboard/timezone
│   ├── FEAT-0005-openscad-environment.yaml          # draft
│   ├── FEAT-0006-esp32-development-environment.yaml # draft
│   └── _template.yaml                               # Template for new specs
└── schemas/
    └── feature-spec.schema.json                     # Spec validation schema
specs.config.yaml              # Central spec registry
```

### Module Map
```
[Feature Spec] → [Review & Approval] → [Autoinstall.yaml implementation]
      │                                          │
      ▼                                          ▼
[Acceptance Criteria]                   [Validated YAML sections]
      │                                          │
      ▼                                          ▼
[Test Scenarios]                        [Integration test: VM boot]
```

---

## 5. Development Rules

### Must Follow
1. **Spec before YAML** — No changes to `Autoinstall.yaml` without an approved spec
2. **No secrets in YAML** — Passwords, tokens, and credentials must never be hardcoded
3. **Interactive sections for identity** — Hostname, username, and password must remain interactive
4. **Validate YAML syntax** — All autoinstall YAML must parse as valid YAML before merging

### Prefer
1. Minimal interactive sections — automate everything that does not require per-machine values
2. `curtin in-target` for all late-command chroot operations
3. Explicit APT mirror over GeoIP-selected mirrors
4. `reboot` after installation so the machine boots directly into the installed system

### Avoid
1. Hardcoded credentials of any kind
2. Pinning to specific Ubuntu point releases — use `$REL` variables where supported
3. Adding unvetted third-party repositories in late-commands without a spec
4. Conflating the example file with the actual configuration

---

## 6. Testing Requirements

### Coverage Expectations
| Type | Target | Focus |
|------|--------|-------|
| Syntax validation | 100% | YAML parses without errors |
| Integration | All acceptance criteria | VM boot with autoinstall YAML |
| Manual smoke test | Post-install state | Packages, snaps, UFW, user account |

### Test Locations
```
tests/
└── (to be defined when FEAT-0001 is implemented)
```

---

## 7. Environment Setup

### Prerequisites
```bash
# To test autoinstall YAML in a VM
qemu-system-x86_64  # or VirtualBox / VMware
# Ubuntu Desktop ISO (24.04 LTS or later)
# A machine or VM with at least 25 GB disk and 4 GB RAM
```

### Quick Start
```bash
# Clone
git clone https://github.com/jvanheerikhuize/Autoinstall-YAML.git
cd Autoinstall-YAML

# Review the active spec
cat specs/features/FEAT-0001-ubuntu-developer-workstation.yaml

# When FEAT-0001 is approved, implement it as Autoinstall.yaml
# Then test by booting an Ubuntu ISO with the YAML passed via:
#   - cloud-init DS (nocloud)
#   - HTTP server reference
#   - Direct subiquity parameter
```

### Environment Variables
| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | No | For AI-assisted spec implementation via Claude Code |

---

## 8. AI Assistant Guidelines

### When Generating YAML
1. **Read the spec first** — Implement exactly what FEAT-0001 (or the active spec) requires
2. **No extras** — Do not add sections, packages, or commands not in the spec
3. **Validate syntax** — Ensure output is valid YAML before writing
4. **No secrets** — Never write passwords, tokens, or keys into the YAML

### When Answering Questions
1. **Reference the spec** — Point to acceptance criteria IDs (AC-001, AC-002, etc.)
2. **Reference Ubuntu docs** — Ubuntu Autoinstall reference at ubuntu.com/server/docs/install/autoinstall-reference
3. **Stay current** — Check "Current State" above for active work

### When Debugging
1. **Check known issues** — Review section above first
2. **Check installer logs** — `/var/log/installer/` on the installed system
3. **Validate YAML** — Use a YAML linter before testing in a VM

### Forbidden Actions
- Write credentials into any YAML file
- Implement features not covered by an approved spec
- Add third-party APT repositories without explicit spec approval

---

## 9. Related Documentation

### Internal
- [specs/](../specs/) — Feature specifications
- [architecture/](architecture/) — Technical architecture
- [decisions/](decisions/) — Architecture Decision Records

### External
- [Ubuntu Autoinstall Reference](https://ubuntu.com/server/docs/install/autoinstall-reference)
- [Ubuntu Autoinstall Quick Start](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Subiquity on GitHub](https://github.com/canonical/subiquity)

---

## 10. Contacts

| Role | Contact |
|------|---------|
| Owner | Jerry van Heerikhuize (@jvanheerikhuize) |

---

## Document Maintenance

| Field | Value |
|-------|-------|
| Last Updated | 2026-02-24 |
| Update Frequency | After each spec is implemented or project state changes |
| Owner | Jerry van Heerikhuize |

### Update Checklist
When updating this document:
- [ ] Update "Current State" section
- [ ] Review "Key Files" for accuracy
- [ ] Check "Known Issues" is current
- [ ] Verify links are working
