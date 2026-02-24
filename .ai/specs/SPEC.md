# Product Specification

> **For AI Assistants**: This document defines WHAT the product does. For HOW it's structured, see `../architecture/ARCHITECTURE.md`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Status | Active |
| Last Updated | 2026-02-24 |
| Owner | Jerry van Heerikhuize |

---

## 1. Product Overview

### 1.1 Vision
> Autoinstall YAML enables engineers and developers to provision consistent, security-baseline Ubuntu developer workstations from a bare machine in a single unattended run.

### 1.2 Problem Statement
**Current State**: Setting up a developer workstation on Ubuntu requires manual intervention through the graphical installer, followed by manual package installation, firewall configuration, and tool setup. Every reinstall or new machine starts from scratch.

**Impact**: Each manual setup takes 30–90 minutes of active engineer time. Machines drift from each other over time. Security baselines (firewall, drivers, codec support) are inconsistently applied. Onboarding a new developer requires tribal knowledge.

**Root Cause**: There is no reproducible, version-controlled configuration that captures the desired end-state of a developer workstation.

### 1.3 Solution Summary
Autoinstall YAML solves this by:
1. Providing a formal, version-controlled `Autoinstall.yaml` that fully describes the desired system state
2. Automating all installation decisions except those that must be per-machine (network, identity)
3. Enforcing a consistent security baseline (UFW, third-party drivers, codec support) on every provisioned machine
4. Using spec-based development so every change to the configuration is reviewed and tracked

---

## 2. Users & Personas

### 2.1 Target Users

| Persona | Description | Primary Goal |
|---------|-------------|--------------|
| Developer | Provisions their own workstation or reinstalls after hardware issues | Reproducible, fast setup with all tools ready |
| Sysadmin / IT | Deploys machines for developers in a team | Consistent baseline across all machines without babysitting the installer |

### 2.2 User Journey
```
[Boot Ubuntu ISO] → [Network config (interactive)] → [Identity config (interactive)]
        → [Automated installation] → [Machine reboots]
        → [First boot: system is ready with all tools installed]
```

---

## 3. Functional Requirements

### 3.1 Core Features

#### Feature: Minimal Desktop Base
- **ID**: F-001
- **Priority**: Must Have
- **Description**: Install Ubuntu Desktop with the minimal source profile
- **User Story**: As a developer, I want a lean desktop base so that I can add only what I need without removing unwanted default apps
- **Acceptance Criteria**: See FEAT-0001 AC-001

#### Feature: Mostly Automated Installation
- **ID**: F-002
- **Priority**: Must Have
- **Description**: All installation decisions are automated except network and identity
- **User Story**: As a developer, I want to only provide my network config and identity once, then leave the machine to finish on its own
- **Acceptance Criteria**: See FEAT-0001 AC-002, AC-003, AC-004

#### Feature: LVM Storage Layout
- **ID**: F-003
- **Priority**: Must Have
- **Description**: Disk is automatically partitioned with LVM
- **User Story**: As a developer, I want LVM so I can resize volumes later if my needs change
- **Acceptance Criteria**: See FEAT-0001 AC-006

#### Feature: Developer Package Set
- **ID**: F-004
- **Priority**: Must Have
- **Description**: A curated set of developer tools is installed automatically
- **User Story**: As a developer, I want git, curl, build-essential and other base tools available immediately after first boot
- **Acceptance Criteria**: See FEAT-0001 AC-007, AC-008

#### Feature: Security Baseline
- **ID**: F-005
- **Priority**: Must Have
- **Description**: UFW firewall, third-party drivers, and codec support are configured automatically
- **User Story**: As a developer, I want my machine to be secure by default without having to remember to enable the firewall manually
- **Acceptance Criteria**: See FEAT-0001 AC-009, AC-010, AC-012

#### Feature: Deterministic APT Mirror
- **ID**: F-006
- **Priority**: Must Have
- **Description**: APT is always configured to use the official Ubuntu archive, with GeoIP disabled
- **User Story**: As a developer, I want consistent package sources regardless of where I install the machine
- **Acceptance Criteria**: See FEAT-0001 AC-005

#### Feature: Full Updates Before First Boot
- **ID**: F-007
- **Priority**: Must Have
- **Description**: All security and general updates are applied during installation
- **User Story**: As a developer, I want my machine to be fully up-to-date the moment I first log in
- **Acceptance Criteria**: See FEAT-0001 AC-011

#### Feature: Reboot After Installation
- **ID**: F-008
- **Priority**: Should Have
- **Description**: Machine reboots automatically after installation completes
- **User Story**: As a developer, I want the machine to reboot directly into the installed system when the installation finishes
- **Acceptance Criteria**: See FEAT-0001 AC-015

### 3.2 Feature Roadmap

| Phase | Features | Spec | Status |
|-------|----------|------|--------|
| v1.0 — Developer workstation | F-001 through F-008 | FEAT-0001 | approved / implemented |
| v1.0 — Locale, keyboard, timezone | Automated locale/keyboard/timezone | FEAT-0004 | approved / implemented |
| v1.1 — OpenSCAD environment | OpenSCAD 3D modeling tools | FEAT-0005 | draft |
| v1.1 — ESP32 environment | ESP32 toolchain + Arduino IDE | FEAT-0006 | draft |
| v1.2 — Full disk encryption | LUKS encryption layer | FEAT-0002 (planned) | — |
| v1.2 — Corporate enrollment | MDM / Intune enrollment | FEAT-0003 (planned) | — |

---

## 4. Non-Functional Requirements

### 4.1 Reliability
| Metric | Target |
|--------|--------|
| Successful unattended install rate | 100% on supported hardware |
| Late-command failure handling | Non-critical commands use `|| true` |

### 4.2 Security
- No credentials hardcoded in any YAML file
- UFW firewall enabled with deny-inbound default policy
- APT fallback set to `abort` — never install from unverified mirrors
- Third-party driver installation is explicit (`install: true`), not silent

### 4.3 Compatibility
- **Ubuntu release**: 24.04 LTS (Noble) and later
- **Architecture**: amd64 primary; arm64/armhf via ports mirror
- **Hardware**: Any hardware supported by Ubuntu 24.04 LTS

### 4.4 Maintainability
- All changes to `Autoinstall.yaml` must trace back to an approved spec
- Spec files are versioned and stored in `specs/features/`
- Conventional commits format for all changes

---

## 5. Constraints & Assumptions

### 5.1 Constraints
- Ubuntu Autoinstall format version 1 (subiquity) only
- Must not embed secrets — identity is always interactive
- Must be idempotent where possible in late-commands

### 5.2 Assumptions
- Target machines have internet access during installation (for APT and snaps)
- Machines are amd64 architecture (default mirror config targets amd64)
- Installer is booted from an official Ubuntu Desktop ISO (not Server ISO)

### 5.3 Dependencies
| Dependency | Type | Notes |
|------------|------|-------|
| Ubuntu Desktop ISO (24.04+) | External | Required to boot the installer |
| archive.ubuntu.com | External service | APT packages during install |
| snapcraft.io | External service | Snap packages during install |

---

## 6. Out of Scope

- Corporate MDM / endpoint management (e.g. Intune, Jamf) — separate spec
- Full disk encryption (LUKS) — separate spec
- VPN or corporate proxy configuration — separate spec
- IDE configuration and dotfile management — handled post-install
- Server or headless deployments — different source profile required
- Multi-disk or RAID storage layouts

---

## 7. Success Metrics

### 7.1 Key Performance Indicators
| Metric | Target |
|--------|--------|
| Time from ISO boot to first login | < 45 minutes on supported hardware |
| Manual steps required | 2 (network config, identity config) |
| Packages missing after first boot | 0 (all spec packages present) |
| UFW status after first boot | active (enabled) |

### 7.2 Definition of Done
The configuration is considered complete when:
- [ ] All acceptance criteria in FEAT-0001 pass
- [ ] Machine successfully installs and reboots unattended (after network + identity)
- [ ] All specified packages and snaps are present on first boot
- [ ] UFW is active on first boot
- [ ] No credentials are present in the YAML

---

## 8. Glossary

| Term | Definition |
|------|------------|
| Autoinstall | Ubuntu's mechanism for unattended installation using a YAML configuration file |
| Subiquity | The Ubuntu installer backend that processes the autoinstall YAML |
| Curtin | The storage and command execution backend used by subiquity |
| `late-commands` | Commands run in a chroot of the installed system after the base install is complete |
| `interactive-sections` | YAML key listing sections where the installer pauses for user input |
| LVM | Logical Volume Manager — flexible disk partitioning scheme used for the storage layout |
| UFW | Uncomplicated Firewall — the firewall tool used for the security baseline |
| `curtin in-target` | Executes a command inside the chroot of the target installation |

---

## Appendix

### A. References
- [Ubuntu Autoinstall Reference](https://ubuntu.com/server/docs/install/autoinstall-reference)
- [Ubuntu Autoinstall Quick Start](https://ubuntu.com/server/docs/install/autoinstall-quickstart)
- [Subiquity GitHub](https://github.com/canonical/subiquity)
- [FEAT-0001 Spec](../../specs/features/FEAT-0001-ubuntu-developer-workstation.yaml)

### B. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-24 | Jerry van Heerikhuize | Initial version |
